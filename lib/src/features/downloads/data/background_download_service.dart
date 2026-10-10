import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

import '../domain/download_category.dart';
import '../domain/download_item.dart';

class BackgroundDownloadService {
  BackgroundDownloadService();

  final FileDownloader _downloader = FileDownloader();
  final MemoryTaskQueue queue = MemoryTaskQueue();
  StreamSubscription<TaskUpdate>? _updatesSub;

  Future<void> init({
    required void Function(TaskStatusUpdate update) onStatus,
    required void Function(TaskProgressUpdate update) onProgress,
    int maxConcurrent = 3,
    bool notifications = true,
  }) async {
    queue.maxConcurrent = maxConcurrent.clamp(1, 5);
    queue.maxConcurrentByHost = 2;
    queue.minInterval = const Duration(milliseconds: 150);
    _downloader.addTaskQueue(queue);

    _updatesSub ??= _downloader.updates.listen((update) {
      if (update is TaskStatusUpdate) {
        onStatus(update);
      } else if (update is TaskProgressUpdate) {
        onProgress(update);
      }
    });

    await _downloader.start(autoCleanDatabase: false);

    if (notifications) {
      _downloader.configureNotification(
        running: const TaskNotification('تندرو', 'در حال دانلود {filename}'),
        complete: const TaskNotification('دانلود کامل شد', '{filename}'),
        error: const TaskNotification('دانلود ناموفق بود', '{filename}'),
        paused: const TaskNotification('دانلود متوقف شد', '{filename}'),
        progressBar: true,
        tapOpensFile: true,
      );
    }

    await _downloader.resumeFromBackground();
  }

  Future<void> ensureNotificationPermission() async {
    const permissionType = PermissionType.notifications;
    var status = await _downloader.permissions.status(permissionType);
    if (status == PermissionStatus.granted) return;
    await _downloader.permissions.request(permissionType);
  }

  Future<void> updateRuntimeSettings({
    required int maxConcurrent,
    required bool wifiOnly,
  }) async {
    queue.maxConcurrent = maxConcurrent.clamp(1, 5);
    await _downloader.requireWiFi(
      wifiOnly ? RequireWiFi.forAllTasks : RequireWiFi.forNoTasks,
      rescheduleRunningTasks: true,
    );
  }

  DownloadTask taskForItem(
    DownloadItem item, {
    required bool wifiOnly,
    required int retries,
    Map<String, String> headers = const {},
  }) {
    final category = detectDownloadCategory(item.fileName);
    final directory = item.relativeDirectory ??
        'downloads/${categoryFolderName(category)}';

    return DownloadTask(
      taskId: item.id,
      url: item.url,
      filename: item.fileName,
      directory: directory,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      requiresWiFi: wifiOnly,
      retries: retries.clamp(0, 5),
      headers: headers,
      allowPause: true,
      transferHints: const {
        TransferHint.userInitiated,
        TransferHint.largeFile,
      },
    );
  }

  Future<bool> enqueue(
    DownloadItem item, {
    required bool wifiOnly,
    required int retries,
    Map<String, String> headers = const {},
  }) async {
    final task = taskForItem(
      item,
      wifiOnly: wifiOnly,
      retries: retries,
      headers: headers,
    );
    queue.add(task);
    return true;
  }

  Future<bool> pause(String id) async {
    final task = await _downloader.taskForId(id);
    return task is DownloadTask ? _downloader.pause(task) : false;
  }

  Future<bool> resume(String id) async {
    final task = await _downloader.taskForId(id);
    return task is DownloadTask ? _downloader.resume(task) : false;
  }

  bool get isWiFi => _downloader.isWiFi;

  Future<bool> cancel(String id) => _downloader.cancelTaskWithId(id);

  Future<String?> moveToTondroSharedStorage(
    DownloadItem item,
  ) async {
    var permission = await _downloader.permissions.status(
      PermissionType.androidSharedStorage,
    );

    if (permission != PermissionStatus.granted) {
      permission = await _downloader.permissions.request(
        PermissionType.androidSharedStorage,
      );
    }

    if (permission != PermissionStatus.granted) {
      return null;
    }

    final category = detectDownloadCategory(item.fileName);
    var folder = item.relativeDirectory ?? categoryFolderName(category);
    folder = folder
        .replaceFirst(
          RegExp(r'^downloads/?', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'^/+|/+$'), '');

    if (folder.isEmpty) {
      folder = categoryFolderName(category);
    }

    return _downloader.moveFileToSharedStorage(
      item.savePath,
      SharedStorage.downloads,
      directory: 'Tondro/$folder',
      mimeType: mimeTypeForFileName(item.fileName),
    );
  }

  Future<bool> openFile(String filePath) {
    return _downloader.openFile(filePath: filePath);
  }

  Future<void> configureNotifications(
    bool enabled, {
    bool showComplete = true,
  }) async {
    if (enabled) {
      _downloader.configureNotification(
        running: const TaskNotification('تندرو', 'در حال دانلود {filename}'),
        complete: showComplete
            ? const TaskNotification('دانلود کامل شد', '{filename}')
            : null,
        error: const TaskNotification('دانلود ناموفق بود', '{filename}'),
        paused: const TaskNotification('دانلود متوقف شد', '{filename}'),
        progressBar: true,
        tapOpensFile: true,
      );
    } else {
      _downloader.configureNotification(
        running: null,
        complete: null,
        error: null,
        paused: null,
      );
    }
  }

  Future<void> dispose() async {
    await _updatesSub?.cancel();
    _updatesSub = null;
  }
}