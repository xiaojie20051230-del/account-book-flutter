import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF4CAF50);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
    cardTheme: const CardThemeData(elevation: 0),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
    cardTheme: const CardThemeData(elevation: 0),
  );
}
