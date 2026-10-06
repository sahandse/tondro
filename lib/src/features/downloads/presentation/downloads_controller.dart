import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/download_store.dart';
import '../data/http_download_service.dart';
import '../domain/download_category.dart';
import '../domain/download_item.dart';

class DownloadsController extends ChangeNotifier {
  DownloadsController({
    DownloadStore? store,
    HttpDownloadService? service,
    this.maxConcurrentDownloads = 3,
    this.maxAutoRetries = 2,
  })  : _store = store ?? DownloadStore(),
        _service = service ?? HttpDownloadService();

  final DownloadStore _store;
  final HttpDownloadService _service;
  final List<DownloadItem> _items = [];
  final Set<String> _activeIds = {};

  int maxConcurrentDownloads;
  int maxAutoRetries;

  bool _loading = true;
  bool get loading => _loading;
  List<DownloadItem> get items => List.unmodifiable(_items);
  int get activeCount => _activeIds.length;

  Future<void> init() async {
    final stored = await _store.load();
    _items
      ..clear()
      ..addAll(stored.map((item) {
        if (item.status == DownloadStatus.downloading) {
          return item.copyWith(
            status: DownloadStatus.queued,
            speedBytesPerSecond: 0,
          );
        }
        return item;
      }));
    _loading = false;
    notifyListeners();
    await _persist();
    _pumpQueue();
  }

  Future<void> addUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || !{'http', 'https'}.contains(uri.scheme)) {
      throw const FormatException('لینک دانلود معتبر نیست.');
    }

    final directory = await getApplicationDocumentsDirectory();

    final fallbackName = 'download-${DateTime.now().millisecondsSinceEpoch}';
    final fileName = uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.last)
        : fallbackName;
    final category = detectDownloadCategory(fileName);
    final downloadsDir = Directory(
      '${directory.path}/downloads/${categoryFolderName(category)}',
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
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
    _pumpQueue();
  }

  Future<void> start(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    if (_activeIds.length >= maxConcurrentDownloads) {
      _items[index] = _items[index].copyWith(
        status: DownloadStatus.queued,
        speedBytesPerSecond: 0,
        clearError: true,
      );
      notifyListeners();
      await _persist();
      return;
    }

    if (_activeIds.contains(id)) return;
    unawaited(_runDownload(id));
  }

  Future<void> _runDownload(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0 || _activeIds.contains(id)) return;

    _activeIds.add(id);
    _items[index] = _items[index].copyWith(
      status: DownloadStatus.downloading,
      speedBytesPerSecond: 0,
      clearError: true,
    );
    notifyListeners();
    await _persist();

    var lastBytes = _items[index].receivedBytes;
    var lastTick = DateTime.now();

    try {
      final current = _items[index];
      await _service.download(
        id: id,
        url: current.url,
        savePath: current.savePath,
        onProgress: (received, total) {
          final liveIndex = _items.indexWhere((e) => e.id == id);
          if (liveIndex < 0) return;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastTick).inMilliseconds;
          var speed = _items[liveIndex].speedBytesPerSecond;

          if (elapsedMs >= 500) {
            final deltaBytes = received - lastBytes;
            speed = elapsedMs > 0 ? (deltaBytes * 1000) / elapsedMs : 0;
            lastBytes = received;
            lastTick = now;
          }

          _items[liveIndex] = _items[liveIndex].copyWith(
            receivedBytes: received,
            totalBytes: total,
            speedBytesPerSecond: speed,
          );
          notifyListeners();
        },
      );

      final doneIndex = _items.indexWhere((e) => e.id == id);
      if (doneIndex >= 0 && _items[doneIndex].status == DownloadStatus.downloading) {
        _items[doneIndex] = _items[doneIndex].copyWith(
          status: DownloadStatus.completed,
          speedBytesPerSecond: 0,
          retryCount: 0,
        );
      }
    } catch (_) {
      final failedIndex = _items.indexWhere((e) => e.id == id);
      if (failedIndex >= 0 &&
          _items[failedIndex].status == DownloadStatus.downloading) {
        final retry = _items[failedIndex].retryCount + 1;
        final shouldRetry = retry <= maxAutoRetries;

        _items[failedIndex] = _items[failedIndex].copyWith(
          status: shouldRetry ? DownloadStatus.queued : DownloadStatus.failed,
          speedBytesPerSecond: 0,
          retryCount: retry,
          errorMessage: shouldRetry
              ? 'اتصال قطع شد؛ تلاش دوباره در صف قرار گرفت.'
              : 'دانلود انجام نشد. دوباره تلاش کن.',
        );
      }
    } finally {
      _activeIds.remove(id);
      notifyListeners();
      await _persist();
      _pumpQueue();
    }
  }

  Future<void> pause(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(
      status: DownloadStatus.paused,
      speedBytesPerSecond: 0,
    );
    _service.pause(id);
    _activeIds.remove(id);
    notifyListeners();
    await _persist();
    _pumpQueue();
  }

  Future<void> remove(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _service.pause(id);
    _activeIds.remove(id);
    final item = _items.removeAt(index);
    final file = File(item.savePath);
    if (await file.exists()) await file.delete();

    notifyListeners();
    await _persist();
    _pumpQueue();
  }

  Future<void> retry(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(
      status: DownloadStatus.queued,
      retryCount: 0,
      speedBytesPerSecond: 0,
      clearError: true,
    );
    notifyListeners();
    await _persist();
    _pumpQueue();
  }

  void updateMaxConcurrentDownloads(int value) {
    maxConcurrentDownloads = value.clamp(1, 5);
    _pumpQueue();
    notifyListeners();
  }

  void _pumpQueue() {
    if (_activeIds.length >= maxConcurrentDownloads) return;

    final available = maxConcurrentDownloads - _activeIds.length;
    final queued = _items
        .where((item) => item.status == DownloadStatus.queued)
        .take(available)
        .toList();

    for (final item in queued) {
      unawaited(_runDownload(item.id));
    }
  }

  Future<void> _persist() => _store.save(_items);
}
