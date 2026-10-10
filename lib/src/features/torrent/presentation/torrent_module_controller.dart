import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dtorrent_task_v2/dtorrent_task_v2.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:path_provider/path_provider.dart';

class TorrentSession {
  TorrentSession({
    required this.id,
    required this.name,
    required this.source,
    this.status = 'در انتظار',
    this.metadataProgress = 0,
    this.progress = 0,
    this.downloadSpeed = 0,
    this.connectedPeers = 0,
    this.task,
  });

  final String id;
  final String name;
  final String source;
  String status;
  double metadataProgress;
  double progress;
  double downloadSpeed;
  int connectedPeers;
  TorrentTask? task;
}

class TorrentModuleController extends ChangeNotifier {
  TorrentModuleController() {
    _ticker = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _refreshRuntimeStats(),
    );
  }

  final List<TorrentSession> _sessions = [];
  final List<Object> _listeners = [];
  Timer? _ticker;

  List<TorrentSession> get sessions => List.unmodifiable(_sessions);

  Future<TorrentModel> inspectTorrentFile(String path) =>
      TorrentModel.parse(path);

  Future<void> addTorrentFile(
    String path, {
    List<int>? selectedFiles,
  }) async {
    final directory = await _torrentDirectory();
    final name = path.split(RegExp(r'[\\/]')).last;
    final session = TorrentSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      source: path,
      status: 'در حال آماده‌سازی',
    );
    _sessions.insert(0, session);
    notifyListeners();

    try {
      final model = await TorrentModel.parse(path);
      final task = TorrentTask.newTask(model, directory.path);
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        task.applySelectedFiles(selectedFiles);
      }
      session.task = task;
      _bindTask(session, task);
      session.status = 'در حال دانلود';
      notifyListeners();
      await task.start();
    } catch (_) {
      session.status = 'خطا';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMagnet(String uri) async {
    final magnet = MagnetParser.parse(uri);
    if (magnet == null) {
      throw const FormatException('Magnet معتبر نیست.');
    }

    final name = magnet.displayName ?? 'Magnet download';
    final session = TorrentSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      source: uri,
      status: 'دریافت Metadata',
    );
    _sessions.insert(0, session);
    notifyListeners();

    final directory = await _torrentDirectory();
    final metadata = MetadataDownloader.fromMagnet(uri);
    final completer = Completer<TorrentTask>();
    final listener = metadata.createListener();
    _listeners.add(listener);

    listener
      ..on<MetaDataDownloadProgress>((event) {
        session.metadataProgress = event.progress.clamp(0, 1).toDouble();
        notifyListeners();
      })
      ..on<MetaDataDownloadComplete>((event) async {
        try {
          final wrappedTorrent = Uint8List.fromList([
            ...ascii.encode('d4:info'),
            ...event.data,
            0x65,
          ]);
          final model = TorrentParser.parseBytes(wrappedTorrent);

          final task = TorrentTask.newTask(
            model,
            directory.path,
            false,
            magnet.webSeeds.isNotEmpty ? magnet.webSeeds : null,
            magnet.acceptableSources.isNotEmpty
                ? magnet.acceptableSources
                : null,
          );

          if (magnet.selectedFileIndices != null &&
              magnet.selectedFileIndices!.isNotEmpty) {
            task.applySelectedFiles(magnet.selectedFileIndices!);
          }

          session.task = task;
          session.metadataProgress = 1;
          session.status = 'در حال دانلود';
          _bindTask(session, task);
          notifyListeners();
          await task.start();

          for (final peer in metadata.activePeers) {
            task.addPeer(peer.address, PeerSource.manual, type: peer.type);
          }

          if (magnet.trackers.isNotEmpty) {
            final hash = magnet.infoHashString;
            final infoHashBuffer = Uint8List.fromList(
              List.generate(hash.length ~/ 2, (index) {
                final value = hash.substring(index * 2, index * 2 + 2);
                return int.parse(value, radix: 16);
              }),
            );
            for (final tracker in magnet.trackers) {
              task.startAnnounceUrl(tracker, infoHashBuffer);
            }
          }

          if (!completer.isCompleted) completer.complete(task);
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      })
      ..on<MetaDataDownloadFailed>((event) {
        if (!completer.isCompleted) {
          completer.completeError(StateError(event.error));
        }
      });

    unawaited(metadata.startDownload());

    try {
      await completer.future.timeout(const Duration(minutes: 3));
    } catch (_) {
      session.status = 'خطا در Metadata';
      notifyListeners();
      rethrow;
    }
  }

  void _bindTask(TorrentSession session, TorrentTask task) {
    final listener = task.createListener();
    _listeners.add(listener);
    listener
      ..on<TaskCompleted>((event) {
        session.status = 'کامل شد';
        notifyListeners();
      })
      ..on<TaskStopped>((event) {
        if (session.status != 'کامل شد') {
          session.status = 'متوقف شد';
          notifyListeners();
        }
      });
  }

  void applySelectedFiles(String id, List<int> indices) {
    final session = _find(id);
    final task = session?.task;
    if (task == null || indices.isEmpty) return;
    task.applySelectedFiles(indices);
    notifyListeners();
  }

  void _refreshRuntimeStats() {
    var changed = false;
    for (final session in _sessions) {
      final task = session.task;
      if (task == null) continue;

      final nextProgress = task.progress.clamp(0, 1).toDouble();
      final nextSpeed = task.currentDownloadSpeed;
      final nextPeers = task.connectedPeersNumber;

      if ((session.progress - nextProgress).abs() > .001 ||
          (session.downloadSpeed - nextSpeed).abs() > 1024 ||
          session.connectedPeers != nextPeers) {
        session.progress = nextProgress;
        session.downloadSpeed = nextSpeed;
        session.connectedPeers = nextPeers;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void pause(String id) {
    final session = _find(id);
    session?.task?.pause();
    if (session != null) {
      session.status = 'متوقف';
      notifyListeners();
    }
  }

  void resume(String id) {
    final session = _find(id);
    session?.task?.resume();
    if (session != null) {
      session.status = 'در حال دانلود';
      notifyListeners();
    }
  }

  Future<void> stop(String id) async {
    final session = _find(id);
    await session?.task?.stop();
    if (session != null) {
      session.status = 'متوقف شد';
      notifyListeners();
    }
  }

  TorrentSession? _find(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<Directory> _torrentDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/downloads/Torrents');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }


  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    for (final session in _sessions) {
      unawaited(session.task?.dispose());
    }
    super.dispose();
  }
}