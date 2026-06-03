import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../core/logger/app_logger.dart';
import '../data/repositories/itransaction_repo.dart';
import '../models/transaction.dart';
import '../models/trash_item.dart';

class TransactionProvider extends ChangeNotifier {
  final ITransactionRepo repo;
  final Box? _trashBox;

  TransactionProvider(this.repo, [this._trashBox]) {
    _load();
    _cleanupTrash();
  }

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  double _monthlyBudget = 0;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get monthlyBudget => _monthlyBudget;

  set monthlyBudget(double value) {
    _monthlyBudget = value;
    notifyListeners();
  }

  String _searchQuery = '';
  String? _filterCategoryId;

  List<Transaction> get filteredTransactions {
    var result = _transactions;
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) =>
        t.note.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_filterCategoryId != null) {
      result = result.where((t) => t.categoryId == _filterCategoryId).toList();
    }
    if (_matchTxIds != null) {
      result = result.where((t) => _matchTxIds!.contains(t.id)).toList();
    }
    return result;
  }

  Set<String>? _matchTxIds;

  void search(String query, {Set<String>? matchTxIds}) {
    _searchQuery = query;
    _matchTxIds = (matchTxIds != null && matchTxIds.isNotEmpty) ? matchTxIds : null;
    notifyListeners();
  }

  void filterByCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategoryId = null;
    notifyListeners();
  }

  List<Transaction> getByMonth(int year, int month) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  // ============ 回收站 ============

  List<TrashItem> get trashItems {
    if (_trashBox == null) return [];
    return _trashBox!.values.map((e) => TrashItem.fromJson(Map<String, dynamic>.from(e))).toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  Future<void> moveToTrash(Transaction transaction) async {
    AppLogger.i('移入回收站', tag: 'TransactionProvider', data: {'id': transaction.id});
    try {
      await repo.delete(transaction.id);
      _transactions.removeWhere((t) => t.id == transaction.id);
      notifyListeners();

      if (_trashBox != null) {
        final item = TrashItem(
          id: transaction.id,
          amount: transaction.amount,
          categoryId: transaction.categoryId,
          note: transaction.note,
          date: transaction.date,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
          deletedAt: DateTime.now(),
        );
        await _trashBox!.put(transaction.id, item.toJson());
      }
    } catch (e, stackTrace) {
      AppLogger.e('移入回收站失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> restoreFromTrash(String id) async {
    AppLogger.i('从回收站恢复', tag: 'TransactionProvider', data: {'id': id});
    try {
      if (_trashBox == null) return;
      final data = _trashBox!.get(id);
      if (data == null) return;
      final item = TrashItem.fromJson(Map<String, dynamic>.from(data));
      final tx = Transaction(
        id: item.id,
        amount: item.amount,
        categoryId: item.categoryId,
        note: item.note,
        date: item.date,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
      await repo.add(tx);
      _transactions.insert(0, tx);
      await _trashBox!.delete(id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('恢复失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> permanentlyDelete(String id) async {
    AppLogger.i('永久删除', tag: 'TransactionProvider', data: {'id': id});
    try {
      await _trashBox?.delete(id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('永久删除失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> emptyTrash() async {
    AppLogger.i('清空回收站', tag: 'TransactionProvider');
    try {
      await _trashBox?.clear();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('清空回收站失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  void _cleanupTrash() {
    if (_trashBox == null) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toDelete = <dynamic>[];
    for (final key in _trashBox!.keys) {
      final data = _trashBox!.get(key);
      if (data == null) continue;
      final deletedAt = DateTime.parse(data['deletedAt'] as String);
      if (deletedAt.isBefore(cutoff)) {
        toDelete.add(key);
      }
    }
    for (final key in toDelete) {
      _trashBox!.delete(key);
    }
    if (toDelete.isNotEmpty) {
      AppLogger.i('清理过期回收站', tag: 'TransactionProvider', data: {'count': toDelete.length});
    }
  }

  // ============ CRUD ============

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await repo.getAll();
      AppLogger.i('账单加载完成', tag: 'TransactionProvider', data: {'count': _transactions.length});
    } catch (e, stackTrace) {
      AppLogger.e('账单加载失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(Transaction transaction) async {
    AppLogger.i('添加账单', tag: 'TransactionProvider', data: {'amount': transaction.amount});
    try {
      await repo.add(transaction);
      _transactions.insert(0, transaction);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('添加账单失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> update(Transaction transaction) async {
    AppLogger.i('更新账单', tag: 'TransactionProvider', data: {'id': transaction.id});
    try {
      final updated = transaction.copyWith(updatedAt: DateTime.now());
      await repo.update(updated);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updated;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      AppLogger.e('更新账单失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> delete(String id) async {
    AppLogger.i('删除账单', tag: 'TransactionProvider', data: {'id': id});
    try {
      await repo.delete(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('删除账单失败', tag: 'TransactionProvider', error: e, stackTrace: stackTrace);
    }
  }
}
