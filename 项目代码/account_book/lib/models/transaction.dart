import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachmentIds;

  const Transaction({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note = '',
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.attachmentIds = const [],
  });

  bool get isIncome => amount >= 0;

  Transaction copyWith({
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    DateTime? updatedAt,
    List<String>? attachmentIds,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'note': note,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'attachmentIds': attachmentIds,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    categoryId: json['categoryId'] as String,
    note: json['note'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    attachmentIds: (json['attachmentIds'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  static Transaction create({
    required double amount,
    required String categoryId,
    String note = '',
    DateTime? date,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'Transaction($id, $amount, $categoryId, $date)';
}
