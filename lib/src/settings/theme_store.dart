import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore {
  static const _kThemeMode = 'theme_mode';
  static const _kAccentSeed = 'accent_seed';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_kThemeMode) ?? '').trim().toLowerCase();

    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      case '':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kThemeMode, raw);
  }

  static Map<String, Color> accentOptions() => <String, Color>{
        'Purple': Colors.deepPurple,
        'Cyan': Colors.cyan,
        'Pink': Colors.pink,
        'Orange': Colors.orange,
        'Green': Colors.green,
      };

  Future<String> loadAccentName() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_kAccentSeed) ?? '').trim();
    final options = accentOptions();
    if (raw.isNotEmpty && options.containsKey(raw)) return raw;
    return 'Purple';
  }

  Future<Color> loadAccentSeedColor() async {
    final name = await loadAccentName();
    return accentOptions()[name] ?? Colors.deepPurple;
  }

  Future<void> saveAccentName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final options = accentOptions();
    final safe = options.containsKey(name) ? name : 'Purple';
    await prefs.setString(_kAccentSeed, safe);
  }
}
