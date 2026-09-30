import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  // Default is LIGHT mode by default as requested
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('masroufi_theme_mode');
      if (saved == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else if (saved == 'light') {
        themeMode.value = ThemeMode.light;
      } else {
        // Default strictly Light
        themeMode.value = ThemeMode.light;
      }
    } catch (_) {}
  }

  static void toggleTheme() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = next;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('masroufi_theme_mode', next == ThemeMode.dark ? 'dark' : 'light');
    });
  }

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('masroufi_theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
    });
  }
}
