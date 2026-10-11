import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TondroThemePreset {
  system,
  light,
  dark,
  amoled,
  ocean,
}

String tondroThemeLabelFa(TondroThemePreset value) => switch (value) {
      TondroThemePreset.system => 'سیستم',
      TondroThemePreset.light => 'روشن',
      TondroThemePreset.dark => 'تیره',
      TondroThemePreset.amoled => 'AMOLED',
      TondroThemePreset.ocean => 'آبی',
    };

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const _key = 'appearance.themePreset';

  TondroThemePreset _preset = TondroThemePreset.system;
  TondroThemePreset get preset => _preset;

  ThemeMode get mode => switch (_preset) {
        TondroThemePreset.system => ThemeMode.system,
        TondroThemePreset.light => ThemeMode.light,
        TondroThemePreset.dark ||
        TondroThemePreset.amoled ||
        TondroThemePreset.ocean =>
          ThemeMode.dark,
      };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    _preset = TondroThemePreset.values.firstWhere(
      (item) => item.name == value,
      orElse: () {
        final legacy = prefs.getString('appearance.themeMode');
        return switch (legacy) {
          'light' => TondroThemePreset.light,
          'dark' => TondroThemePreset.dark,
          _ => TondroThemePreset.system,
        };
      },
    );
  }

  Future<void> setPreset(TondroThemePreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preset.name);
  }
}
