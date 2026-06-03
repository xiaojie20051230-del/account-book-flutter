import 'package:flutter_test/flutter_test.dart';

import 'package:account_book/models/transaction.dart';
import 'package:account_book/models/category.dart';
import 'package:account_book/core/utils/date_util.dart';

void main() {
  group('Transaction', () {
    test('create 生成有效实例', () {
      final t = Transaction.create(amount: 100, categoryId: 'cat-test');
      expect(t.id, isNotEmpty);
      expect(t.isIncome, isTrue);
    });

    test('JSON 回环一致', () {
      final t = Transaction.create(amount: -29.9, categoryId: 'cat-food', note: '午餐');
      expect(Transaction.fromJson(t.toJson()).amount, t.amount);
    });
  });

  group('Category', () {
    test('预置分类数量正确', () {
      expect(Category.presetExpenses().length, 8);
      expect(Category.presetIncomes().length, 4);
    });
  });

  group('DateUtil', () {
    test('formatDate 格式正确', () {
      expect(DateUtil.formatDate(DateTime(2026, 6, 2)), '2026-06-02');
    });
  });
}
