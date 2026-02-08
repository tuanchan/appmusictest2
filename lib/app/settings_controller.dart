// app/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _kThemeMode = 'themeMode'; // 'light' | 'dark'
  static const _kAppTitle = 'appTitle';

  ThemeMode _themeMode = ThemeMode.light;
  String _appTitle = 'AppMusicVol2';

  ThemeMode get themeMode => _themeMode;
  String get appTitle => _appTitle;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    final theme = sp.getString(_kThemeMode);
    _themeMode = (theme == 'dark') ? ThemeMode.dark : ThemeMode.light;

    final title = sp.getString(_kAppTitle);
    if (title != null && title.trim().isNotEmpty) {
      _appTitle = title.trim();
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setAppTitle(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    if (_appTitle == t) return;

    _appTitle = t;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAppTitle, t);
  }
}
