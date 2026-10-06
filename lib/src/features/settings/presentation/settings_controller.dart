import 'package:flutter/foundation.dart';

import '../data/settings_store.dart';
import '../domain/download_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStore? store}) : _store = store ?? SettingsStore();

  final SettingsStore _store;
  DownloadSettings _settings = const DownloadSettings();
  bool _loading = true;

  DownloadSettings get settings => _settings;
  bool get loading => _loading;

  Future<void> init() async {
    _settings = await _store.load();
    _loading = false;
    notifyListeners();
  }

  Future<void> update(DownloadSettings value) async {
    _settings = value;
    notifyListeners();
    await _store.save(_settings);
  }
}
