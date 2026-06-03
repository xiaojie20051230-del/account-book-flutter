import '../../models/category.dart';

abstract class ICategoryRepo {
  Future<List<Category>> getAll();
  Future<List<Category>> getByType(bool isIncome);
  Future<void> add(Category category);
  Future<void> delete(String id);
}
