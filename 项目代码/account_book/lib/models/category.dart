import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final bool isIncome;
  final bool isPreset;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isIncome,
    this.isPreset = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'isIncome': isIncome,
    'isPreset': isPreset,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    isIncome: json['isIncome'] as bool,
    isPreset: json['isPreset'] as bool? ?? false,
  );

  static Category create({
    required String name,
    required String icon,
    required bool isIncome,
  }) {
    return Category(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      isIncome: isIncome,
    );
  }

  /// 预置支出分类
  static List<Category> presetExpenses() => [
    Category(id: 'cat-food', name: '餐饮', icon: '🍽️', isIncome: false, isPreset: true),
    Category(id: 'cat-transport', name: '交通', icon: '🚌', isIncome: false, isPreset: true),
    Category(id: 'cat-shopping', name: '购物', icon: '🛒', isIncome: false, isPreset: true),
    Category(id: 'cat-entertain', name: '娱乐', icon: '🎮', isIncome: false, isPreset: true),
    Category(id: 'cat-housing', name: '居住', icon: '🏠', isIncome: false, isPreset: true),
    Category(id: 'cat-education', name: '教育', icon: '📚', isIncome: false, isPreset: true),
    Category(id: 'cat-health', name: '医疗', icon: '💊', isIncome: false, isPreset: true),
    Category(id: 'cat-other', name: '其他', icon: '📌', isIncome: false, isPreset: true),
  ];

  /// 预置收入分类
  static List<Category> presetIncomes() => [
    Category(id: 'cat-salary', name: '工资', icon: '💰', isIncome: true, isPreset: true),
    Category(id: 'cat-parttime', name: '兼职', icon: '💼', isIncome: true, isPreset: true),
    Category(id: 'cat-gift', name: '红包', icon: '🧧', isIncome: true, isPreset: true),
    Category(id: 'cat-other-income', name: '其他', icon: '📌', isIncome: true, isPreset: true),
  ];
}
