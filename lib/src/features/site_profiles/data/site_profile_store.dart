import 'package:shared_preferences/shared_preferences.dart';

import '../domain/site_profile.dart';

class SiteProfileStore {
  static const _key = 'site_profiles_v1';

  Future<List<SiteProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const <String>[];
    return values.map(SiteProfile.fromJson).toList();
  }

  Future<void> save(List<SiteProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      profiles.map((profile) => profile.toJson()).toList(),
    );
  }
}
