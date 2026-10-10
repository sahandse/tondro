import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BrowserRecord {
  const BrowserRecord({
    required this.url,
    required this.title,
    required this.timestamp,
  });

  final String url;
  final String title;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'url': url,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BrowserRecord.fromMap(Map<String, dynamic> map) => BrowserRecord(
        url: map['url'] as String,
        title: map['title'] as String? ?? map['url'] as String,
        timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

class BrowserStore {
  static const _historyKey = 'browser.history.v1';
  static const _bookmarkKey = 'browser.bookmarks.v1';

  Future<List<BrowserRecord>> history() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_historyKey));
  }

  Future<List<BrowserRecord>> bookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_bookmarkKey));
  }

  Future<void> addHistory(String url, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final records = _decode(prefs.getStringList(_historyKey))
      ..removeWhere((item) => item.url == url)
      ..insert(
        0,
        BrowserRecord(
          url: url,
          title: title,
          timestamp: DateTime.now(),
        ),
      );
    await prefs.setStringList(
      _historyKey,
      records.take(200).map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  Future<void> toggleBookmark(String url, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final records = _decode(prefs.getStringList(_bookmarkKey));
    final exists = records.any((item) => item.url == url);
    if (exists) {
      records.removeWhere((item) => item.url == url);
    } else {
      records.insert(
        0,
        BrowserRecord(
          url: url,
          title: title,
          timestamp: DateTime.now(),
        ),
      );
    }
    await prefs.setStringList(
      _bookmarkKey,
      records.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  Future<bool> isBookmarked(String url) async {
    final records = await bookmarks();
    return records.any((item) => item.url == url);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  List<BrowserRecord> _decode(List<String>? values) {
    if (values == null) return <BrowserRecord>[];
    final result = <BrowserRecord>[];
    for (final value in values) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        result.add(BrowserRecord.fromMap(map));
      } catch (_) {}
    }
    return result;
  }
}
