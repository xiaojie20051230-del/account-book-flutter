import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const _key = 'theme_mode';
  Box? _settingsBox;
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  ThemeData get theme => _mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;

  void init(Box settingsBox) {
    _settingsBox = settingsBox;
    final saved = settingsBox.get(_key, defaultValue: 'light') as String;
    _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggle() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _settingsBox?.put(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    _settingsBox?.put(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
