import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../downloads/data/download_store.dart';
import '../../downloads/domain/download_category.dart';
import '../../downloads/domain/download_item.dart';
import '../../settings/data/settings_store.dart';
import '../../settings/domain/download_settings.dart';
import '../../site_profiles/data/site_profile_store.dart';
import '../../site_profiles/domain/site_profile.dart';

class BackupResult {
  const BackupResult({
    required this.downloads,
    required this.profiles,
  });

  final int downloads;
  final int profiles;
}

class AppBackupService {
  AppBackupService({
    DownloadStore? downloadStore,
    SettingsStore? settingsStore,
    SiteProfileStore? profileStore,
  })  : _downloadStore = downloadStore ?? DownloadStore(),
        _settingsStore = settingsStore ?? SettingsStore(),
        _profileStore = profileStore ?? SiteProfileStore();

  final DownloadStore _downloadStore;
  final SettingsStore _settingsStore;
  final SiteProfileStore _profileStore;

  Future<Uri?> exportBackup() async {
    final downloads = await _downloadStore.load();
    final settings = await _settingsStore.load();
    final profiles = await _profileStore.load();

    final data = <String, dynamic>{
      'format': 'tondro-backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': _settingsToMap(settings),
      'profiles': profiles.map((e) => e.toMap()).toList(),
      'downloads': downloads.map((e) => e.toMap()).toList(),
    };

    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(pretty));
    final date = DateTime.now();
    final suffix =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return FilePicker.saveFile(
      dialogTitle: 'ذخیره بکاپ تندرو',
      fileName: 'tondro-backup-$suffix.json',
      bytes: bytes,
      mimeType: 'application/json',
    );
  }

  Future<BackupResult?> importBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final root = jsonDecode(utf8.decode(bytes));
    if (root is! Map<String, dynamic> || root['format'] != 'tondro-backup') {
      throw const FormatException('فایل بکاپ تندرو معتبر نیست.');
    }

    final settingsMap = root['settings'];
    if (settingsMap is Map<String, dynamic>) {
      await _settingsStore.save(_settingsFromMap(settingsMap));
    }

    final profilesRaw = root['profiles'];
    final profiles = <SiteProfile>[];
    if (profilesRaw is List) {
      for (final value in profilesRaw) {
        if (value is Map) {
          profiles.add(
            SiteProfile.fromMap(Map<String, dynamic>.from(value)),
          );
        }
      }
      await _profileStore.save(profiles);
    }

    final downloadsRaw = root['downloads'];
    final downloads = <DownloadItem>[];
    if (downloadsRaw is List) {
      final documents = await getApplicationDocumentsDirectory();
      for (final value in downloadsRaw) {
        if (value is! Map) continue;
        final original = DownloadItem.fromMap(
          Map<String, dynamic>.from(value),
        );

        final originalFile = File(original.savePath);
        if (await originalFile.exists()) {
          downloads.add(original);
          continue;
        }

        final relativeDirectory = original.relativeDirectory ??
            'downloads/${categoryFolderName(detectDownloadCategory(original.fileName))}';
        final directory = Directory('${documents.path}/$relativeDirectory');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        downloads.add(
          DownloadItem(
            id: original.id,
            url: original.url,
            fileName: original.fileName,
            savePath: '${directory.path}/${original.fileName}',
            createdAt: original.createdAt,
            relativeDirectory: relativeDirectory,
            status: DownloadStatus.paused,
            receivedBytes: 0,
            totalBytes: original.totalBytes,
            retryCount: 0,
          ),
        );
      }
      await _downloadStore.save(downloads);
    }

    return BackupResult(
      downloads: downloads.length,
      profiles: profiles.length,
    );
  }

  Map<String, dynamic> _settingsToMap(DownloadSettings value) => {
        'maxConcurrentDownloads': value.maxConcurrentDownloads,
        'wifiOnly': value.wifiOnly,
        'autoRetry': value.autoRetry,
        'clipboardDetection': value.clipboardDetection,
        'notifications': value.notifications,
        'speedLimitKbps': value.speedLimitKbps,
        'maxSegments': value.maxSegments,
        'smartSegments': value.smartSegments,
        'networkProfile': value.networkProfile.name,
        'completionAction': value.completionAction.name,
      };

  DownloadSettings _settingsFromMap(Map<String, dynamic> map) =>
      DownloadSettings(
        maxConcurrentDownloads:
            (map['maxConcurrentDownloads'] as num?)?.toInt() ?? 3,
        wifiOnly: map['wifiOnly'] as bool? ?? false,
        autoRetry: (map['autoRetry'] as num?)?.toInt() ?? 2,
        clipboardDetection: map['clipboardDetection'] as bool? ?? true,
        notifications: map['notifications'] as bool? ?? true,
        speedLimitKbps: (map['speedLimitKbps'] as num?)?.toInt() ?? 0,
        maxSegments: (map['maxSegments'] as num?)?.toInt() ?? 4,
        smartSegments: map['smartSegments'] as bool? ?? true,
        networkProfile: NetworkProfilePreset.values.firstWhere(
          (value) => value.name == map['networkProfile'],
          orElse: () => NetworkProfilePreset.balanced,
        ),
        completionAction: CompletionAction.values.firstWhere(
          (value) => value.name == map['completionAction'],
          orElse: () => CompletionAction.notify,
        ),
      );
}