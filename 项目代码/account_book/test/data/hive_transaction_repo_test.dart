import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:account_book/data/datasources/hive_transaction_repo.dart';
import 'package:account_book/models/transaction.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late HiveTransactionRepo repo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_transactions');
    repo = HiveTransactionRepo(box);
  });

  tearDown(() async {
    await box.close();
    tempDir.deleteSync(recursive: true);
  });

  group('add / getAll', () {
    test('添加后 getAll 能查到', () async {
      final t = Transaction.create(
        amount: -29.9,
        categoryId: 'cat-food',
        note: '午餐',
        date: DateTime(2026, 6, 2),
      );
      await repo.add(t);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, t.id);
    });

    test('多条数据按日期倒序返回', () async {
      final t1 = Transaction.create(
        amount: -10,
        categoryId: 'cat-a',
        date: DateTime(2026, 6, 1),
      );
      final t2 = Transaction.create(
        amount: -20,
        categoryId: 'cat-b',
        date: DateTime(2026, 6, 2),
      );
      await repo.add(t1);
      await repo.add(t2);

      final all = await repo.getAll();
      expect(all.length, 2);
      expect(all[0].id, t2.id); // 最新在前
      expect(all[1].id, t1.id);
    });
  });

  group('getByDate', () {
    test('日期范围过滤正确', () async {
      await repo.add(Transaction.create(
        amount: -10, categoryId: 'cat-a', date: DateTime(2026, 6, 1),
      ));
      await repo.add(Transaction.create(
        amount: -20, categoryId: 'cat-b', date: DateTime(2026, 6, 15),
      ));
      await repo.add(Transaction.create(
        amount: -30, categoryId: 'cat-c', date: DateTime(2026, 7, 1),
      ));

      final result = await repo.getByDate(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );
      expect(result.length, 2);
    });
  });

  group('getByMonth', () {
    test('月份过滤正确', () async {
      await repo.add(Transaction.create(
        amount: -10, categoryId: 'cat-a', date: DateTime(2026, 5, 15),
      ));
      await repo.add(Transaction.create(
        amount: -20, categoryId: 'cat-b', date: DateTime(2026, 6, 1),
      ));
      await repo.add(Transaction.create(
        amount: -30, categoryId: 'cat-c', date: DateTime(2026, 6, 30),
      ));

      final result = await repo.getByMonth(2026, 6);
      expect(result.length, 2);
    });
  });

  group('update', () {
    test('更新后字段变化', () async {
      final t = Transaction.create(
        amount: -10, categoryId: 'cat-a', note: '旧备注',
      );
      await repo.add(t);

      final updated = t.copyWith(amount: -99, note: '新备注');
      await repo.update(updated);

      final all = await repo.getAll();
      expect(all.first.amount, -99);
      expect(all.first.note, '新备注');
    });
  });

  group('delete', () {
    test('删除后查不到', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a');
      await repo.add(t);
      await repo.delete(t.id);

      final all = await repo.getAll();
      expect(all.length, 0);
    });
  });

  group('分页', () {
    test('limit 参数生效', () async {
      for (int i = 0; i < 10; i++) {
        await repo.add(Transaction.create(
          amount: -10.0 * i, categoryId: 'cat-a',
        ));
      }

      final result = await repo.getAll(limit: 3);
      expect(result.length, 3);
    });

    test('offset 参数生效', () async {
      for (int i = 0; i < 5; i++) {
        await repo.add(Transaction.create(
          amount: -10.0 * i, categoryId: 'cat-a',
        ));
      }

      final first2 = await repo.getAll(limit: 2, offset: 0);
      final next2 = await repo.getAll(limit: 2, offset: 2);

      expect(first2.length, 2);
      expect(next2.length, 2);
      expect(first2[0].id, isNot(next2[0].id));
    });
  });
}
