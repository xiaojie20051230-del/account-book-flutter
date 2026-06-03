import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:account_book/data/datasources/hive_category_repo.dart';
import 'package:account_book/models/category.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late HiveCategoryRepo repo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_categories');
    repo = HiveCategoryRepo(box);
  });

  tearDown(() async {
    await box.close();
    tempDir.deleteSync(recursive: true);
  });

  group('预置分类初始化', () {
    test('空库首次加载自动初始化预置', () async {
      final all = await repo.getAll();
      expect(all.length, 12); // 8 支出 + 4 收入
    });

    test('第二次加载不会重复初始化', () async {
      final first = await repo.getAll();
      final second = await repo.getAll();
      expect(first.length, second.length);
    });

    test('预置分类含有全部必需字段', () async {
      final all = await repo.getAll();
      for (final c in all) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
        expect(c.icon, isNotEmpty);
      }
    });
  });

  group('add', () {
    test('添加后 getAll 包含新分类', () async {
      final cat = Category.create(name: '宠物', icon: '🐱', isIncome: false);
      await repo.add(cat);

      final all = await repo.getAll();
      expect(all.any((c) => c.id == cat.id), isTrue);
    });
  });

  group('delete', () {
    test('删除后查不到', () async {
      final cat = Category.create(name: '临时', icon: '📌', isIncome: false);
      await repo.add(cat);
      await repo.delete(cat.id);

      final all = await repo.getAll();
      expect(all.any((c) => c.id == cat.id), isFalse);
    });

    test('删除预置分类不崩溃', () async {
      final all = await repo.getAll();
      final preset = all.firstWhere((c) => c.isPreset);
      await repo.delete(preset.id);

      final after = await repo.getAll();
      expect(after.any((c) => c.id == preset.id), isFalse);
    });
  });

  group('getByType', () {
    test('返回支出分类', () async {
      final result = await repo.getByType(false);
      for (final c in result) {
        expect(c.isIncome, isFalse);
      }
    });

    test('返回收入分类', () async {
      final result = await repo.getByType(true);
      for (final c in result) {
        expect(c.isIncome, isTrue);
      }
    });
  });
}
