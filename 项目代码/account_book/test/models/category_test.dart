import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/models/category.dart';

void main() {
  group('预置分类', () {
    test('预设支出分类 8 个', () {
      final expenses = Category.presetExpenses();
      expect(expenses.length, 8);
      for (final c in expenses) {
        expect(c.isIncome, isFalse);
        expect(c.isPreset, isTrue);
        expect(c.id, startsWith('cat-'));
      }
    });

    test('预设收入分类 4 个', () {
      final incomes = Category.presetIncomes();
      expect(incomes.length, 4);
      for (final c in incomes) {
        expect(c.isIncome, isTrue);
        expect(c.isPreset, isTrue);
        expect(c.id, startsWith('cat-'));
      }
    });

    test('所有预置 ID 唯一', () {
      final all = [...Category.presetExpenses(), ...Category.presetIncomes()];
      final ids = all.map((c) => c.id).toSet();
      expect(ids.length, all.length);
    });

    test('预置分类 name 和 icon 非空', () {
      final all = [...Category.presetExpenses(), ...Category.presetIncomes()];
      for (final c in all) {
        expect(c.name, isNotEmpty);
        expect(c.icon, isNotEmpty);
      }
    });
  });

  group('Category.create()', () {
    test('自定义支出分类', () {
      final c = Category.create(
        name: '宠物',
        icon: '🐱',
        isIncome: false,
      );

      expect(c.name, '宠物');
      expect(c.icon, '🐱');
      expect(c.isIncome, isFalse);
      expect(c.isPreset, isFalse);
      expect(c.id, isNotEmpty);
    });

    test('自定义收入分类', () {
      final c = Category.create(
        name: '投资',
        icon: '📈',
        isIncome: true,
      );

      expect(c.isIncome, isTrue);
    });
  });

  group('Category JSON 序列化', () {
    test('toJson → fromJson 回环一致', () {
      final original = Category.create(name: '测试', icon: '📌', isIncome: false);
      final json = original.toJson();
      final restored = Category.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.isIncome, original.isIncome);
      expect(restored.isPreset, original.isPreset);
    });
  });
}
