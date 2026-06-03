import 'package:flutter/foundation.dart' hide Category;
import '../core/logger/app_logger.dart';
import '../data/repositories/icategory_repo.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final ICategoryRepo _repo;

  CategoryProvider(this._repo) {
    _load();
  }

  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  List<Category> get expenses => _categories.where((c) => !c.isIncome).toList();
  List<Category> get incomes => _categories.where((c) => c.isIncome).toList();

  Category? getById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _repo.getAll();
      AppLogger.i('分类加载完成', tag: 'CategoryProvider', data: {'count': _categories.length});
    } catch (e, stackTrace) {
      AppLogger.e('分类加载失败', tag: 'CategoryProvider', error: e, stackTrace: stackTrace);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(Category category) async {
    AppLogger.i('添加分类', tag: 'CategoryProvider', data: {'name': category.name});
    try {
      await _repo.add(category);
      _categories.add(category);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('添加分类失败', tag: 'CategoryProvider', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> delete(String id) async {
    AppLogger.i('删除分类', tag: 'CategoryProvider', data: {'id': id});
    try {
      await _repo.delete(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('删除分类失败', tag: 'CategoryProvider', error: e, stackTrace: stackTrace);
    }
  }
}
