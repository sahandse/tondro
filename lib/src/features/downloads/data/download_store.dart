import 'package:shared_preferences/shared_preferences.dart';

import '../domain/download_item.dart';

class DownloadStore {
  static const _key = 'download_history_v1';

  Future<List<DownloadItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    return values.map(DownloadItem.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(List<DownloadItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => e.toJson()).toList());
  }
}
