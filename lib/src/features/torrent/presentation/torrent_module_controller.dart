import 'dart:async';
import 'dart:typed_data';

import 'package:dtorrent_task_v2/dtorrent_task_v2.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TorrentSession {
  TorrentSession({
    required this.id,
    required this.name,
    required this.source,
    this.status = 'در انتظار',
    this.metadataProgress = 0,
    this.task,
  });

  final String id;
  final String name;
  final String source;
  String status;
  double metadataProgress;
  TorrentTask? task;
}

class TorrentModuleController extends ChangeNotifier {
  final List<TorrentSession> _sessions = [];
  final List<Object> _listeners = [];

  List<TorrentSession> get sessions => List.unmodifiable(_sessions);

  Future<void> addTorrentFile(String path) async {
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

    final parsedUri = Uri.tryParse(uri);
    final name = parsedUri?.queryParameters['dn'] ?? 'Magnet download';
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
        session.metadataProgress = event.progress.clamp(0, 1);
        notifyListeners();
      })
      ..on<MetaDataDownloadComplete>((event) async {
        try {
          final msg = decode(event.data);
          final torrentMap = <String, dynamic>{'info': msg};
          final model = parseTorrentFileContent(torrentMap);
          if (model == null) {
            throw const FormatException('Metadata قابل استفاده نیست.');
          }

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

          final metadataPeers = metadata.activePeers;
          for (final peer in metadataPeers) {
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
      });

    metadata.startDownload();

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
}