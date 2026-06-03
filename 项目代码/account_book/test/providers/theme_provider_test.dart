import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      provider = ThemeProvider();
    });

    test('默认主题为浅色模式', () {
      expect(provider.mode, ThemeMode.light);
    });

    test('toggle 切换到深色模式', () {
      provider.toggle();
      expect(provider.mode, ThemeMode.dark);
    });

    test('两次 toggle 回到浅色模式', () {
      provider.toggle();
      provider.toggle();
      expect(provider.mode, ThemeMode.light);
    });

    test('setMode 强制设置主题', () {
      provider.setMode(ThemeMode.dark);
      expect(provider.mode, ThemeMode.dark);
    });
  });
}
