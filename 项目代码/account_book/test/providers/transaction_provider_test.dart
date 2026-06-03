import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:account_book/data/datasources/hive_transaction_repo.dart';
import 'package:account_book/data/datasources/hive_category_repo.dart';
import 'package:account_book/models/transaction.dart';
import 'package:account_book/providers/transaction_provider.dart';

void main() {
  late Directory tempDir;
  late Box txBox;
  late Box catBox;
  late Box trashBox;
  late HiveTransactionRepo repo;
  late TransactionProvider provider;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    txBox = await Hive.openBox('test_tx');
    catBox = await Hive.openBox('test_cat');
    trashBox = await Hive.openBox('test_trash');

    // 初始化预置分类
    final catRepo = HiveCategoryRepo(catBox);
    await catRepo.getAll();

    repo = HiveTransactionRepo(txBox);
    provider = TransactionProvider(repo, trashBox);
    // 等 provider 异步加载完成
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    await txBox.close();
    await catBox.close();
    await trashBox.close();
    tempDir.deleteSync(recursive: true);
  });

  group('初始状态', () {
    test('构造后自动加载，列表为空', () async {
      expect(provider.transactions, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });

  group('add', () {
    test('添加后列表更新', () async {
      final t = Transaction.create(amount: -29.9, categoryId: 'cat-food');
      await provider.add(t);

      expect(provider.transactions.length, 1);
      expect(provider.transactions.first.id, t.id);
    });
  });

  group('delete', () {
    test('删除后列表不包含', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-food');
      await provider.add(t);
      await provider.delete(t.id);

      expect(provider.transactions.any((x) => x.id == t.id), isFalse);
    });
  });

  group('totalIncome', () {
    test('只有支出时收入为 0', () async {
      await provider.add(Transaction.create(amount: -50, categoryId: 'cat-food'));
      expect(provider.totalIncome, 0);
    });

    test('收入汇总正确', () async {
      await provider.add(Transaction.create(amount: 100, categoryId: 'cat-salary'));
      await provider.add(Transaction.create(amount: 200, categoryId: 'cat-parttime'));
      expect(provider.totalIncome, 300);
    });
  });

  group('totalExpense', () {
    test('支出汇总正确（返回绝对值）', () async {
      await provider.add(Transaction.create(amount: -30, categoryId: 'cat-food'));
      await provider.add(Transaction.create(amount: -50, categoryId: 'cat-transport'));
      expect(provider.totalExpense, 80);
    });

    test('混合收支只算支出', () async {
      await provider.add(Transaction.create(amount: -30, categoryId: 'cat-food'));
      await provider.add(Transaction.create(amount: 1000, categoryId: 'cat-salary'));
      expect(provider.totalExpense, 30);
    });
  });

  group('getByMonth', () {
    test('月份过滤正确', () async {
      await provider.add(Transaction.create(
        amount: -10, categoryId: 'cat-a', date: DateTime(2026, 5, 1),
      ));
      await provider.add(Transaction.create(
        amount: -20, categoryId: 'cat-a', date: DateTime(2026, 6, 15),
      ));

      final june = provider.getByMonth(2026, 6);
      expect(june.length, 1);
    });
  });

  group('update', () {
    test('更新后列表同步', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a', note: 'old');
      await provider.add(t);

      final updated = t.copyWith(amount: -99, note: 'new');
      await provider.update(updated);

      final tx = provider.transactions.first;
      expect(tx.amount, -99);
      expect(tx.note, 'new');
    });
  });

  group('trash', () {
    test('moveToTrash 后列表减少', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a');
      await provider.add(t);
      await provider.moveToTrash(t);

      expect(provider.transactions.length, 0);
    });

    test('moveToTrash 后回收站增加', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a');
      await provider.add(t);
      await provider.moveToTrash(t);

      expect(provider.trashItems.length, 1);
      expect(provider.trashItems.first.id, t.id);
    });

    test('restoreFromTrash 恢复到列表', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a');
      await provider.add(t);
      await provider.moveToTrash(t);
      await provider.restoreFromTrash(t.id);

      expect(provider.transactions.length, 1);
      expect(provider.trashItems.length, 0);
    });

    test('permanentlyDelete 从回收站移除', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a');
      await provider.add(t);
      await provider.moveToTrash(t);
      await provider.permanentlyDelete(t.id);

      expect(provider.trashItems.length, 0);
    });

    test('update 自动设置 updatedAt', () async {
      final t = Transaction.create(amount: -10, categoryId: 'cat-a', note: 'old');
      await provider.add(t);
      expect(t.updatedAt, isNull);

      await provider.update(t.copyWith(amount: -99));
      final tx = provider.transactions.first;
      expect(tx.updatedAt, isNotNull);
    });
  });
}
