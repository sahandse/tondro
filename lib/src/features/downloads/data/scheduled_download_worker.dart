import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../settings/data/settings_store.dart';
import '../../site_profiles/data/site_profile_store.dart';
import '../../site_profiles/domain/site_profile.dart';
import '../domain/download_item.dart';
import 'background_download_service.dart';
import 'download_store.dart';

const scheduledDownloadTaskName = 'tondro.scheduled.download';

String _workName(String id) => 'tondro-scheduled-$id';

SiteProfile? _profileForUrl(List<SiteProfile> profiles, String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return null;
  for (final profile in profiles) {
    if (profile.matchesHost(uri.host)) return profile;
  }
  return null;
}

@pragma('vm:entry-point')
void tondroScheduleDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (taskName != scheduledDownloadTaskName) return true;
    final id = inputData?['id'] as String?;
    if (id == null || id.isEmpty) return true;

    try {
      final store = DownloadStore();
      final items = await store.load();
      final index = items.indexWhere((item) => item.id == id);
      if (index < 0) return true;

      final item = items[index];
      if (item.status == DownloadStatus.completed) return true;

      final settings = await SettingsStore().load();
      final profiles = await SiteProfileStore().load();
      final profile = _profileForUrl(profiles, item.url);
      final headers = profile?.requestHeaders ?? const <String, String>{};

      final downloader = FileDownloader();
      await downloader.start(autoCleanDatabase: false);
      await downloader.requireWiFi(
        settings.wifiOnly
            ? RequireWiFi.forAllTasks
            : RequireWiFi.forNoTasks,
        rescheduleRunningTasks: true,
      );
      if (settings.notifications) {
        downloader.configureNotification(
          running: const TaskNotification(
            'تندرو',
            'در حال دانلود {filename}',
          ),
          complete: const TaskNotification(
            'دانلود کامل شد',
            '{filename}',
          ),
          error: const TaskNotification(
            'دانلود ناموفق بود',
            '{filename}',
          ),
          paused: const TaskNotification(
            'دانلود متوقف شد',
            '{filename}',
          ),
          progressBar: true,
          tapOpensFile: true,
        );
      }

      final existing = await downloader.taskForId(id);
      if (existing == null) {
        final service = BackgroundDownloadService();
        final task = service.taskForItem(
          item,
          wifiOnly: settings.wifiOnly,
          retries: settings.autoRetry,
          headers: headers,
        );
        final enqueued = await downloader.enqueue(task);
        if (!enqueued) return false;
      }

      items[index] = item.copyWith(
        status: DownloadStatus.downloading,
        clearSchedule: true,
        clearError: true,
      );
      await store.save(items);
      return true;
    } catch (_) {
      return false;
    }
  });
}

class ScheduledDownloadWorker {
  static Future<void> initialize() =>
      Workmanager().initialize(tondroScheduleDispatcher);

  static Future<void> schedule({
    required String id,
    required DateTime when,
    required bool wifiOnly,
  }) async {
    final delay = when.difference(DateTime.now());
    await Workmanager().registerOneOffTask(
      _workName(id),
      scheduledDownloadTaskName,
      initialDelay: delay.isNegative ? Duration.zero : delay,
      inputData: {'id': id},
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType:
            wifiOnly ? NetworkType.unmetered : NetworkType.connected,
      ),
      tag: 'tondro-scheduled-download',
    );
  }

  static Future<void> cancel(String id) =>
      Workmanager().cancelByUniqueName(_workName(id));
}