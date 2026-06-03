class TrashItem {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime deletedAt;

  const TrashItem({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note = '',
    required this.date,
    required this.createdAt,
    this.updatedAt,
    required this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'note': note,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'deletedAt': deletedAt.toIso8601String(),
  };

  factory TrashItem.fromJson(Map<String, dynamic> json) => TrashItem(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    categoryId: json['categoryId'] as String,
    note: json['note'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    deletedAt: DateTime.parse(json['deletedAt'] as String),
  );
}
