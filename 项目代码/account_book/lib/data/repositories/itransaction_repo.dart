import '../../models/transaction.dart';

abstract class ITransactionRepo {
  Future<List<Transaction>> getAll({int? limit, int? offset});
  Future<List<Transaction>> getByDate(DateTime start, DateTime end);
  Future<List<Transaction>> getByMonth(int year, int month);
  Future<void> add(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> delete(String id);
}
