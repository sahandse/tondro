import 'package:shared_preferences/shared_preferences.dart';

import '../domain/download_settings.dart';

class SettingsStore {
  static const _maxConcurrent = 'settings.maxConcurrentDownloads';
  static const _wifiOnly = 'settings.wifiOnly';
  static const _autoRetry = 'settings.autoRetry';
  static const _clipboard = 'settings.clipboardDetection';
  static const _notifications = 'settings.notifications';
  static const _speedLimit = 'settings.speedLimitKbps';
  static const _maxSegments = 'settings.maxSegments';
  static const _smartSegments = 'settings.smartSegments';
  static const _networkProfile = 'settings.networkProfile';
  static const _completionAction = 'settings.completionAction';

  Future<DownloadSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DownloadSettings(
      maxConcurrentDownloads: prefs.getInt(_maxConcurrent) ?? 3,
      wifiOnly: prefs.getBool(_wifiOnly) ?? false,
      autoRetry: prefs.getInt(_autoRetry) ?? 2,
      clipboardDetection: prefs.getBool(_clipboard) ?? true,
      notifications: prefs.getBool(_notifications) ?? true,
      speedLimitKbps: prefs.getInt(_speedLimit) ?? 0,
      maxSegments: prefs.getInt(_maxSegments) ?? 4,
      smartSegments: prefs.getBool(_smartSegments) ?? true,
      networkProfile: NetworkProfilePreset.values.firstWhere(
        (value) => value.name == prefs.getString(_networkProfile),
        orElse: () => NetworkProfilePreset.balanced,
      ),
      completionAction: CompletionAction.values.firstWhere(
        (value) => value.name == prefs.getString(_completionAction),
        orElse: () => CompletionAction.notify,
      ),
    );
  }

  Future<void> save(DownloadSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_maxConcurrent, settings.maxConcurrentDownloads),
      prefs.setBool(_wifiOnly, settings.wifiOnly),
      prefs.setInt(_autoRetry, settings.autoRetry),
      prefs.setBool(_clipboard, settings.clipboardDetection),
      prefs.setBool(_notifications, settings.notifications),
      prefs.setInt(_speedLimit, settings.speedLimitKbps),
      prefs.setInt(_maxSegments, settings.maxSegments),
      prefs.setBool(_smartSegments, settings.smartSegments),
      prefs.setString(_networkProfile, settings.networkProfile.name),
      prefs.setString(_completionAction, settings.completionAction.name),
    ]);
  }
}
