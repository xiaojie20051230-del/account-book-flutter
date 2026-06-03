import 'package:hive/hive.dart';
import '../../core/logger/app_logger.dart';
import '../../models/transaction.dart';
import '../repositories/itransaction_repo.dart';

class HiveTransactionRepo implements ITransactionRepo {
  final Box _box;

  HiveTransactionRepo(this._box);

  List<Transaction> _all() {
    return _box.values
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Transaction>> getAll({int? limit, int? offset}) async {
    AppLogger.v('获取所有账单', tag: 'HiveTransactionRepo');
    final all = _all();
    final start = offset ?? 0;
    final end = limit != null ? start + limit : all.length;
    return all.sublist(start, end > all.length ? all.length : end);
  }

  @override
  Future<List<Transaction>> getByDate(DateTime start, DateTime end) async {
    AppLogger.v('按日期获取账单', tag: 'HiveTransactionRepo', data: {'start': start.toString(), 'end': end.toString()});
    return _all().where((t) => t.date.isAfter(start.subtract(const Duration(days: 1))) && t.date.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  @override
  Future<List<Transaction>> getByMonth(int year, int month) async {
    AppLogger.v('按月份获取账单', tag: 'HiveTransactionRepo', data: {'year': year, 'month': month});
    return _all().where((t) => t.date.year == year && t.date.month == month).toList();
  }

  @override
  Future<void> add(Transaction transaction) async {
    AppLogger.i('添加账单', tag: 'HiveTransactionRepo', data: {'id': transaction.id, 'amount': transaction.amount});
    await _box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> update(Transaction transaction) async {
    AppLogger.i('更新账单', tag: 'HiveTransactionRepo', data: {'id': transaction.id});
    await _box.put(transaction.id, transaction.toJson());
  }

  @override
  Future<void> delete(String id) async {
    AppLogger.i('删除账单', tag: 'HiveTransactionRepo', data: {'id': id});
    await _box.delete(id);
  }
}
