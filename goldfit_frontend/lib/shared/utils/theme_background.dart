import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeType { light, dark, system }

class ThemeBackgroundApp extends ChangeNotifier {
  ThemeModeType _themeModeType = ThemeModeType.system;

  ThemeMode get themeMode {
    switch (_themeModeType) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }

  ThemeModeType get themeModeType => _themeModeType;

  ThemeBackgroundApp() {
    loadThemeMode();
  }

  void loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    int? index = prefs.getInt('theme_mode');

    if (index != null) {
      _themeModeType = ThemeModeType.values[index];
      notifyListeners();
    }
  }

  void setTheme(ThemeModeType mode) async {
    _themeModeType = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("theme_mode", mode.index);
  }
}