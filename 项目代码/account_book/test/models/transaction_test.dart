import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/models/transaction.dart';

void main() {
  group('Transaction.create()', () {
    test('自动生成 ID 和时间戳', () {
      final t = Transaction.create(
        amount: 100,
        categoryId: 'cat-test',
        note: 'test',
      );

      expect(t.id, isNotEmpty);
      expect(t.createdAt, isNotNull);
      expect(t.date, isNotNull);
    });

    test('正金额 isIncome 为 true', () {
      final t = Transaction.create(amount: 100, categoryId: 'cat-test');
      expect(t.isIncome, isTrue);
    });

    test('负金额 isIncome 为 false', () {
      final t = Transaction.create(amount: -100, categoryId: 'cat-test');
      expect(t.isIncome, isFalse);
    });

    test('零金额 isIncome 为 true', () {
      final t = Transaction.create(amount: 0, categoryId: 'cat-test');
      expect(t.isIncome, isTrue);
    });
  });

  group('Transaction JSON 序列化', () {
    test('toJson → fromJson 回环一致', () {
      final original = Transaction.create(
        amount: 99.9,
        categoryId: 'cat-food',
        note: '午餐',
        date: DateTime(2026, 6, 1),
      );

      final json = original.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.categoryId, original.categoryId);
      expect(restored.note, original.note);
      expect(restored.date, original.date);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('Transaction.copyWith()', () {
    test('只改指定字段', () {
      final original = Transaction.create(
        amount: 100,
        categoryId: 'cat-a',
        note: 'original',
        date: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(amount: 200, note: 'updated');

      expect(updated.amount, 200);
      expect(updated.note, 'updated');
      expect(updated.categoryId, original.categoryId);
      expect(updated.date, original.date);
      expect(updated.id, original.id);
    });
  });
}
