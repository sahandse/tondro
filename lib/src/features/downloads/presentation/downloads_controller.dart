import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/download_store.dart';
import '../data/http_download_service.dart';
import '../domain/download_item.dart';

class DownloadsController extends ChangeNotifier {
  DownloadsController({
    DownloadStore? store,
    HttpDownloadService? service,
  })  : _store = store ?? DownloadStore(),
        _service = service ?? HttpDownloadService();

  final DownloadStore _store;
  final HttpDownloadService _service;
  final List<DownloadItem> _items = [];

  bool _loading = true;
  bool get loading => _loading;
  List<DownloadItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final stored = await _store.load();
    _items
      ..clear()
      ..addAll(stored.map((item) {
        if (item.status == DownloadStatus.downloading) {
          return item.copyWith(status: DownloadStatus.paused);
        }
        return item;
      }));
    _loading = false;
    notifyListeners();
    await _persist();
  }

  Future<void> addUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || !{'http', 'https'}.contains(uri.scheme)) {
      throw const FormatException('لینک دانلود معتبر نیست.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final fallbackName = 'download-${DateTime.now().millisecondsSinceEpoch}';
    final fileName = uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.last)
        : fallbackName;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = DownloadItem(
      id: id,
      url: uri.toString(),
      fileName: fileName,
      savePath: '${downloadsDir.path}/$fileName',
      createdAt: DateTime.now(),
    );

    _items.insert(0, item);
    await _persist();
    notifyListeners();
    await start(id);
  }

  Future<void> start(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(
      status: DownloadStatus.downloading,
      clearError: true,
    );
    notifyListeners();
    await _persist();

    try {
      final current = _items[index];
      await _service.download(
        id: id,
        url: current.url,
        savePath: current.savePath,
        onProgress: (received, total) {
          final liveIndex = _items.indexWhere((e) => e.id == id);
          if (liveIndex < 0) return;
          _items[liveIndex] = _items[liveIndex].copyWith(
            receivedBytes: received,
            totalBytes: total,
          );
          notifyListeners();
        },
      );
      final doneIndex = _items.indexWhere((e) => e.id == id);
      if (doneIndex >= 0 && _items[doneIndex].status == DownloadStatus.downloading) {
        _items[doneIndex] = _items[doneIndex].copyWith(status: DownloadStatus.completed);
      }
    } catch (error) {
      final failedIndex = _items.indexWhere((e) => e.id == id);
      if (failedIndex >= 0 && _items[failedIndex].status == DownloadStatus.downloading) {
        _items[failedIndex] = _items[failedIndex].copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'دانلود انجام نشد. دوباره تلاش کن.',
        );
      }
    }
    notifyListeners();
    await _persist();
  }

  Future<void> pause(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(status: DownloadStatus.paused);
    _service.pause(id);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _service.pause(id);
    final item = _items.removeAt(index);
    final file = File(item.savePath);
    if (await file.exists()) await file.delete();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _store.save(_items);
}
