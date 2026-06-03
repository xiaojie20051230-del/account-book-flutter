import 'package:hive/hive.dart';
import '../../core/logger/app_logger.dart';
import '../../models/category.dart';
import '../repositories/icategory_repo.dart';

class HiveCategoryRepo implements ICategoryRepo {
  final Box _box;

  HiveCategoryRepo(this._box);

  @override
  Future<List<Category>> getAll() async {
    AppLogger.v('获取所有分类', tag: 'HiveCategoryRepo');
    final items = _box.values
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (items.isEmpty) {
      await _initPresets();
      return _box.values
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return items;
  }

  @override
  Future<List<Category>> getByType(bool isIncome) async {
    AppLogger.v('按类型获取分类', tag: 'HiveCategoryRepo');
    final all = await getAll();
    return all.where((c) => c.isIncome == isIncome).toList();
  }

  @override
  Future<void> add(Category category) async {
    AppLogger.i('添加分类', tag: 'HiveCategoryRepo', data: {'id': category.id, 'name': category.name});
    await _box.put(category.id, category.toJson());
  }

  @override
  Future<void> delete(String id) async {
    AppLogger.i('删除分类', tag: 'HiveCategoryRepo', data: {'id': id});
    await _box.delete(id);
  }

  Future<void> _initPresets() async {
    AppLogger.i('初始化预置分类', tag: 'HiveCategoryRepo');
    for (final c in [...Category.presetExpenses(), ...Category.presetIncomes()]) {
      await _box.put(c.id, c.toJson());
    }
  }
}
