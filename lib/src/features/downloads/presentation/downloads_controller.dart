import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../settings/data/settings_store.dart';
import '../../settings/domain/download_settings.dart';
import '../data/background_download_service.dart';
import '../data/download_store.dart';
import '../domain/download_category.dart';
import '../domain/download_item.dart';

class DownloadsController extends ChangeNotifier {
  DownloadsController({
    DownloadStore? store,
    SettingsStore? settingsStore,
    BackgroundDownloadService? service,
  })  : _store = store ?? DownloadStore(),
        _settingsStore = settingsStore ?? SettingsStore(),
        _service = service ?? BackgroundDownloadService();

  final DownloadStore _store;
  final SettingsStore _settingsStore;
  final BackgroundDownloadService _service;
  final List<DownloadItem> _items = [];

  Timer? _schedulerTimer;
  bool _loading = true;
  DownloadSettings _settings = const DownloadSettings();

  bool get loading => _loading;
  List<DownloadItem> get items => List.unmodifiable(_items);
  DownloadSettings get settings => _settings;

  Future<void> init() async {
    _settings = await _settingsStore.load();

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

    await _service.init(
      maxConcurrent: _settings.maxConcurrentDownloads,
      notifications: _settings.notifications,
      onStatus: _handleStatusUpdate,
      onProgress: _handleProgressUpdate,
    );
    await _service.updateRuntimeSettings(
      maxConcurrent: _settings.maxConcurrentDownloads,
      wifiOnly: _settings.wifiOnly,
    );

    _schedulerTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _startDueScheduled(),
    );

    _loading = false;
    notifyListeners();
    await _persist();
    await _startDueScheduled();
    await _enqueueReadyItems();
  }

  Future<void> addUrl(
    String rawUrl, {
    DateTime? scheduledAt,
  }) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !{'http', 'https'}.contains(uri.scheme)) {
      throw const FormatException('لینک دانلود معتبر نیست.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final fallbackName = 'download-${DateTime.now().millisecondsSinceEpoch}';
    final fileName =
        uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty
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
      scheduledAt: scheduledAt,
      status: DownloadStatus.queued,
    );

    _items.insert(0, item);
    await _persist();
    notifyListeners();

    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
      await _enqueue(item);
    }
  }

  Future<void> _enqueueReadyItems() async {
    for (final item in _items) {
      if (item.status != DownloadStatus.queued) continue;
      if (item.scheduledAt != null &&
          item.scheduledAt!.isAfter(DateTime.now())) {
        continue;
      }
      await _enqueue(item);
    }
  }

  Future<void> _startDueScheduled() async {
    final now = DateTime.now();
    final due = _items.where(
      (item) =>
          item.status == DownloadStatus.queued &&
          item.scheduledAt != null &&
          !item.scheduledAt!.isAfter(now),
    );

    for (final item in due.toList()) {
      final index = _items.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(clearSchedule: true);
      }
      await _enqueue(_items[index]);
    }

    if (due.isNotEmpty) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _enqueue(DownloadItem item) async {
    await _service.enqueue(
      item,
      wifiOnly: _settings.wifiOnly,
      retries: _settings.autoRetry,
    );
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final index = _items.indexWhere((item) => item.id == update.task.taskId);
    if (index < 0) return;

    final current = _items[index];
    final status = switch (update.status) {
      TaskStatus.enqueued => DownloadStatus.queued,
      TaskStatus.running => DownloadStatus.downloading,
      TaskStatus.complete => DownloadStatus.completed,
      TaskStatus.paused => DownloadStatus.paused,
      TaskStatus.waitingToRetry => DownloadStatus.queued,
      TaskStatus.failed => DownloadStatus.failed,
      TaskStatus.notFound => DownloadStatus.failed,
      TaskStatus.canceled => DownloadStatus.paused,
    };

    _items[index] = current.copyWith(
      status: status,
      speedBytesPerSecond:
          status == DownloadStatus.downloading
              ? current.speedBytesPerSecond
              : 0,
      errorMessage: status == DownloadStatus.failed
          ? 'دانلود انجام نشد. دوباره تلاش کن.'
          : null,
      clearError: status != DownloadStatus.failed,
      clearSchedule: status == DownloadStatus.downloading ||
          status == DownloadStatus.completed,
    );

    if (status == DownloadStatus.completed &&
        _items[index].totalBytes > 0) {
      _items[index] = _items[index].copyWith(
        receivedBytes: _items[index].totalBytes,
      );
    }

    notifyListeners();
    unawaited(_persist());
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final index = _items.indexWhere((item) => item.id == update.task.taskId);
    if (index < 0 || update.progress < 0) return;

    final total =
        update.expectedFileSize > 0 ? update.expectedFileSize : _items[index].totalBytes;
    final received = total > 0
        ? (total * update.progress.clamp(0.0, 1.0)).round()
        : _items[index].receivedBytes;
    final speed = update.networkSpeed > 0
        ? update.networkSpeed * 1024 * 1024
        : _items[index].speedBytesPerSecond;

    _items[index] = _items[index].copyWith(
      status: DownloadStatus.downloading,
      totalBytes: total,
      receivedBytes: received,
      speedBytesPerSecond: speed,
      clearError: true,
      clearSchedule: true,
    );
    notifyListeners();
  }

  Future<void> pause(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    final item = _items[index];
    if (item.scheduledAt != null && item.scheduledAt!.isAfter(DateTime.now())) {
      _items[index] = item.copyWith(status: DownloadStatus.paused);
      notifyListeners();
      await _persist();
      return;
    }

    await _service.pause(id);
  }

  Future<void> start(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(
      status: DownloadStatus.queued,
      clearSchedule: true,
      clearError: true,
    );
    notifyListeners();
    await _persist();

    final resumed = await _service.resume(id);
    if (!resumed) {
      await _enqueue(_items[index]);
    }
  }

  Future<void> retry(String id) => start(id);

  Future<void> remove(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    await _service.cancel(id);
    final item = _items.removeAt(index);
    final file = File(item.savePath);
    if (await file.exists()) {
      await file.delete();
    }

    notifyListeners();
    await _persist();
  }

  Future<void> updateSettings(DownloadSettings value) async {
    _settings = value;
    await _settingsStore.save(value);
    await _service.updateRuntimeSettings(
      maxConcurrent: value.maxConcurrentDownloads,
      wifiOnly: value.wifiOnly,
    );
    notifyListeners();
  }

  Future<void> schedule(String id, DateTime dateTime) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    await _service.cancel(id);
    _items[index] = _items[index].copyWith(
      status: DownloadStatus.queued,
      scheduledAt: dateTime,
      speedBytesPerSecond: 0,
    );
    notifyListeners();
    await _persist();
    await _startDueScheduled();
  }

  Future<void> _persist() => _store.save(_items);

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    unawaited(_service.dispose());
    super.dispose();
  }
}
