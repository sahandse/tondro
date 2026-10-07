import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../settings/data/settings_store.dart';
import '../../site_profiles/data/site_profile_store.dart';
import '../../site_profiles/domain/site_profile.dart';
import '../../settings/domain/download_settings.dart';
import '../data/background_download_service.dart';
import '../data/download_store.dart';
import '../data/segmented_download_service.dart';
import '../data/throttled_download_service.dart';
import '../domain/download_category.dart';
import '../domain/download_item.dart';

class DownloadsController extends ChangeNotifier {
  DownloadsController({
    DownloadStore? store,
    SettingsStore? settingsStore,
    BackgroundDownloadService? service,
    ThrottledDownloadService? throttledService,
    SegmentedDownloadService? segmentedService,
    SiteProfileStore? siteProfileStore,
  })  : _store = store ?? DownloadStore(),
        _settingsStore = settingsStore ?? SettingsStore(),
        _service = service ?? BackgroundDownloadService(),
        _throttledService = throttledService ?? ThrottledDownloadService(),
        _segmentedService = segmentedService ?? SegmentedDownloadService(),
        _siteProfileStore = siteProfileStore ?? SiteProfileStore();

  final DownloadStore _store;
  final SettingsStore _settingsStore;
  final BackgroundDownloadService _service;
  final ThrottledDownloadService _throttledService;
  final SegmentedDownloadService _segmentedService;
  final SiteProfileStore _siteProfileStore;
  final List<DownloadItem> _items = [];
  final List<SiteProfile> _siteProfiles = [];
  final Set<String> _throttledActive = {};
  final Set<String> _segmentedActive = {};

  Timer? _schedulerTimer;
  bool _loading = true;
  DownloadSettings _settings = const DownloadSettings();

  bool get loading => _loading;
  List<DownloadItem> get items => List.unmodifiable(_items);
  DownloadSettings get settings => _settings;
  List<SiteProfile> get siteProfiles => List.unmodifiable(_siteProfiles);

  Future<void> init() async {
    _settings = await _settingsStore.load();
    _siteProfiles
      ..clear()
      ..addAll(await _siteProfileStore.load());

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
      (_) async {
        await _startDueScheduled();
        _pumpThrottledQueue();
        _pumpSegmentedQueue();
      },
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
    final rawFileName =
        uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty
            ? Uri.decodeComponent(uri.pathSegments.last)
            : fallbackName;
    final safeFileName = _sanitizeFileName(rawFileName, fallbackName);
    final category = detectDownloadCategory(safeFileName);
    final profile = _profileForUrl(uri.toString());
    final profileFolder = profile?.folderName?.trim();
    final relativeDirectory = profileFolder != null && profileFolder.isNotEmpty
        ? 'downloads/${_sanitizeFolderName(profileFolder)}'
        : 'downloads/${categoryFolderName(category)}';
    final downloadsDir = Directory(
      '${directory.path}/$relativeDirectory',
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final fileName = await _uniqueFileName(downloadsDir, safeFileName);

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = DownloadItem(
      id: id,
      url: uri.toString(),
      fileName: fileName,
      savePath: '${downloadsDir.path}/$fileName',
      createdAt: DateTime.now(),
      relativeDirectory: relativeDirectory,
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

  String _sanitizeFileName(String value, String fallback) {
    final sanitized = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      return fallback;
    }
    return sanitized;
  }


  String _sanitizeFolderName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'Other' : sanitized;
  }

  SiteProfile? _profileForUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    for (final profile in _siteProfiles) {
      if (profile.matchesHost(uri.host)) return profile;
    }
    return null;
  }

  Map<String, String> _headersFor(DownloadItem item) =>
      _profileForUrl(item.url)?.requestHeaders ?? const <String, String>{};

  int _segmentsFor(DownloadItem item) {
    final profileSegments = _profileForUrl(item.url)?.maxSegments;
    return (profileSegments ?? _settings.maxSegments).clamp(1, 16);
  }

  Future<void> saveSiteProfile(SiteProfile profile) async {
    final index = _siteProfiles.indexWhere((item) => item.id == profile.id);
    if (index >= 0) {
      _siteProfiles[index] = profile;
    } else {
      _siteProfiles.add(profile);
    }
    await _siteProfileStore.save(_siteProfiles);
    notifyListeners();
  }

  Future<void> deleteSiteProfile(String id) async {
    _siteProfiles.removeWhere((profile) => profile.id == id);
    await _siteProfileStore.save(_siteProfiles);
    notifyListeners();
  }

  Future<String> _uniqueFileName(Directory directory, String original) async {
    final dot = original.lastIndexOf('.');
    final hasExtension = dot > 0 && dot < original.length - 1;
    final base = hasExtension ? original.substring(0, dot) : original;
    final extension = hasExtension ? original.substring(dot) : '';

    var candidate = original;
    var counter = 1;
    while (await File('${directory.path}/$candidate').exists() ||
        _items.any((item) => item.savePath == '${directory.path}/$candidate')) {
      candidate = '$base ($counter)$extension';
      counter++;
    }
    return candidate;
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
    if (_settings.notifications) {
      await _service.ensureNotificationPermission();
    }
    if (_settings.speedLimitKbps > 0) {
      _pumpThrottledQueue();
      return;
    }
    if (_segmentsFor(item) > 1) {
      _pumpSegmentedQueue();
      return;
    }
    await _service.enqueue(
      item,
      wifiOnly: _settings.wifiOnly,
      retries: _settings.autoRetry,
      headers: _headersFor(item),
    );
  }

  void _pumpSegmentedQueue() {
    if (_settings.speedLimitKbps > 0) return;
    if (_settings.wifiOnly && !_service.isWiFi) return;

    final available =
        _settings.maxConcurrentDownloads - _segmentedActive.length;
    if (available <= 0) return;

    final now = DateTime.now();
    final ready = _items.where((item) {
      if (item.status != DownloadStatus.queued) return false;
      if (_segmentsFor(item) <= 1) return false;
      if (_segmentedActive.contains(item.id)) return false;
      return item.scheduledAt == null || !item.scheduledAt!.isAfter(now);
    }).take(available).toList();

    for (final item in ready) {
      unawaited(_runSegmented(item.id));
    }
  }

  Future<void> _runSegmented(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _segmentedActive.contains(id)) return;

    _segmentedActive.add(id);
    _items[index] = _items[index].copyWith(
      status: DownloadStatus.downloading,
      speedBytesPerSecond: 0,
      clearError: true,
      clearSchedule: true,
    );
    notifyListeners();
    await _persist();

    var fallbackToBackground = false;
    try {
      final completed = await _segmentedService.download(
        item: _items[index],
        segments: _segmentsFor(_items[index]),
        headers: _headersFor(_items[index]),
        onProgress: (received, total, speed) {
          final liveIndex = _items.indexWhere((item) => item.id == id);
          if (liveIndex < 0) return;
          _items[liveIndex] = _items[liveIndex].copyWith(
            status: DownloadStatus.downloading,
            receivedBytes: received,
            totalBytes: total,
            speedBytesPerSecond: speed,
            clearError: true,
          );
          notifyListeners();
        },
      );

      final doneIndex = _items.indexWhere((item) => item.id == id);
      if (doneIndex < 0) return;

      if (completed) {
        _items[doneIndex] = _items[doneIndex].copyWith(
          status: DownloadStatus.completed,
          receivedBytes: _items[doneIndex].totalBytes,
          speedBytesPerSecond: 0,
        );
      } else {
        fallbackToBackground = true;
        _items[doneIndex] = _items[doneIndex].copyWith(
          status: DownloadStatus.queued,
          speedBytesPerSecond: 0,
        );
      }
    } on SegmentedDownloadCanceled {
      final pausedIndex = _items.indexWhere((item) => item.id == id);
      if (pausedIndex >= 0) {
        _items[pausedIndex] = _items[pausedIndex].copyWith(
          status: DownloadStatus.paused,
          speedBytesPerSecond: 0,
        );
      }
    } catch (_) {
      final failedIndex = _items.indexWhere((item) => item.id == id);
      if (failedIndex >= 0) {
        _items[failedIndex] = _items[failedIndex].copyWith(
          status: DownloadStatus.failed,
          speedBytesPerSecond: 0,
          errorMessage: 'دانلود چندبخشی انجام نشد. دوباره تلاش کن.',
        );
      }
    } finally {
      _segmentedActive.remove(id);
      notifyListeners();
      await _persist();

      final currentIndex = _items.indexWhere((item) => item.id == id);
      if (fallbackToBackground && currentIndex >= 0) {
        await _service.enqueue(
          _items[currentIndex],
          wifiOnly: _settings.wifiOnly,
          retries: _settings.autoRetry,
          headers: _headersFor(_items[currentIndex]),
        );
      } else {
        _pumpSegmentedQueue();
      }
    }
  }

  void _pumpThrottledQueue() {
    if (_settings.speedLimitKbps <= 0) return;
    if (_settings.wifiOnly && !_service.isWiFi) return;
    final available =
        _settings.maxConcurrentDownloads - _throttledActive.length;
    if (available <= 0) return;

    final now = DateTime.now();
    final ready = _items.where((item) {
      if (item.status != DownloadStatus.queued) return false;
      if (_throttledActive.contains(item.id)) return false;
      return item.scheduledAt == null || !item.scheduledAt!.isAfter(now);
    }).take(available).toList();

    for (final item in ready) {
      unawaited(_runThrottled(item.id));
    }
  }

  Future<void> _runThrottled(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _throttledActive.contains(id)) return;

    _throttledActive.add(id);
    _items[index] = _items[index].copyWith(
      status: DownloadStatus.downloading,
      speedBytesPerSecond: 0,
      clearError: true,
      clearSchedule: true,
    );
    notifyListeners();
    await _persist();

    try {
      await _throttledService.download(
        item: _items[index],
        speedLimitKbps: _settings.speedLimitKbps,
        headers: _headersFor(_items[index]),
        onProgress: (received, total, speed) {
          final liveIndex = _items.indexWhere((item) => item.id == id);
          if (liveIndex < 0) return;
          _items[liveIndex] = _items[liveIndex].copyWith(
            status: DownloadStatus.downloading,
            receivedBytes: received,
            totalBytes: total,
            speedBytesPerSecond: speed,
            clearError: true,
          );
          notifyListeners();
        },
      );

      final doneIndex = _items.indexWhere((item) => item.id == id);
      if (doneIndex >= 0 &&
          _items[doneIndex].status == DownloadStatus.downloading) {
        _items[doneIndex] = _items[doneIndex].copyWith(
          status: DownloadStatus.completed,
          speedBytesPerSecond: 0,
        );
      }
    } on ThrottledDownloadCanceled {
      final pausedIndex = _items.indexWhere((item) => item.id == id);
      if (pausedIndex >= 0 &&
          _items[pausedIndex].status == DownloadStatus.downloading) {
        _items[pausedIndex] = _items[pausedIndex].copyWith(
          status: DownloadStatus.paused,
          speedBytesPerSecond: 0,
        );
      }
    } catch (_) {
      final failedIndex = _items.indexWhere((item) => item.id == id);
      if (failedIndex >= 0 &&
          _items[failedIndex].status == DownloadStatus.downloading) {
        _items[failedIndex] = _items[failedIndex].copyWith(
          status: DownloadStatus.failed,
          speedBytesPerSecond: 0,
          errorMessage: 'دانلود انجام نشد. دوباره تلاش کن.',
        );
      }
    } finally {
      _throttledActive.remove(id);
      notifyListeners();
      await _persist();
      _pumpThrottledQueue();
    }
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

    if (_segmentedActive.contains(id)) {
      _segmentedService.pause(id);
      _items[index] = item.copyWith(
        status: DownloadStatus.paused,
        speedBytesPerSecond: 0,
      );
      notifyListeners();
      await _persist();
      return;
    }

    if (_throttledActive.contains(id)) {
      _throttledService.pause(id);
      _items[index] = item.copyWith(
        status: DownloadStatus.paused,
        speedBytesPerSecond: 0,
      );
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

    if (_settings.speedLimitKbps > 0) {
      _pumpThrottledQueue();
      return;
    }
    if (_segmentsFor(_items[index]) > 1) {
      _pumpSegmentedQueue();
      return;
    }

    final resumed = await _service.resume(id);
    if (!resumed) {
      await _enqueue(_items[index]);
    }
  }

  Future<void> retry(String id) => start(id);

  Future<void> remove(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    if (_segmentedActive.contains(id)) {
      _segmentedService.pause(id);
      _segmentedActive.remove(id);
    } else if (_throttledActive.contains(id)) {
      _throttledService.pause(id);
      _throttledActive.remove(id);
    } else {
      await _service.cancel(id);
    }
    final item = _items.removeAt(index);
    final file = File(item.savePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _deleteSegmentParts(item.savePath);

    notifyListeners();
    await _persist();
  }

  Future<void> updateSettings(DownloadSettings value) async {
    final speedChanged = _settings.speedLimitKbps != value.speedLimitKbps;
    final segmentsChanged = _settings.maxSegments != value.maxSegments;
    if (speedChanged || segmentsChanged) {
      for (final id in _segmentedActive.toList()) {
        _segmentedService.pause(id);
      }
      for (final id in _throttledActive.toList()) {
        _throttledService.pause(id);
      }
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.queued) {
          await _service.cancel(item.id);
          _items[i] = item.copyWith(
            status: DownloadStatus.queued,
            speedBytesPerSecond: 0,
          );
        }
      }
      _throttledActive.clear();
      _segmentedActive.clear();
    }

    _settings = value;
    await _settingsStore.save(value);
    await _service.configureNotifications(value.notifications);
    await _service.updateRuntimeSettings(
      maxConcurrent: value.maxConcurrentDownloads,
      wifiOnly: value.wifiOnly,
    );
    notifyListeners();
    await _persist();

    if (value.speedLimitKbps > 0) {
      _pumpThrottledQueue();
    } else if (value.maxSegments > 1) {
      _pumpSegmentedQueue();
    } else {
      await _enqueueReadyItems();
    }
  }

  Future<bool> openFile(String id) async {
    final item = _items.cast<DownloadItem?>().firstWhere(
          (element) => element?.id == id,
          orElse: () => null,
        );
    if (item == null || item.status != DownloadStatus.completed) {
      return false;
    }
    return _service.openFile(item.savePath);
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

  Future<void> _deleteSegmentParts(String savePath) async {
    for (var index = 0; index < 16; index++) {
      final part = File('$savePath.part.$index');
      if (await part.exists()) {
        await part.delete();
      }
    }
  }

  Future<void> _persist() => _store.save(_items);

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    for (final id in _segmentedActive.toList()) {
      _segmentedService.pause(id);
    }
    for (final id in _throttledActive.toList()) {
      _throttledService.pause(id);
    }
    unawaited(_service.dispose());
    super.dispose();
  }
}
