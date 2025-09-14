import 'category.dart';

class MoneyTransaction {
  final int id;
  final int userId;
  final String type; // income | expense
  final double amount;
  final int categoryId;
  final Category? category;
  final String description;
  final DateTime date;

  MoneyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.category,
    required this.description,
    required this.date,
  });

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) => MoneyTransaction(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        type: (json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        categoryId: (json['categoryId'] as num).toInt(),
        category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
        description: (json['description'] ?? '') as String,
        date: DateTime.parse(json['date'] as String),
      );
}

