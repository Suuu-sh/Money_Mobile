import 'package:money_tracker_mobile/models/category.dart';

class FixedExpense {
  final int id;
  final String name;
  final double amount;
  final String type; // 'expense' or 'income'
  final int categoryId;
  final Category? category;
  final String description;

  FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.category,
    required this.description,
  });

  factory FixedExpense.fromJson(Map<String, dynamic> json) => FixedExpense(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        amount: (json['amount'] as num).toDouble(),
        type: (json['type'] ?? 'expense') as String,
        categoryId: (json['categoryId'] ?? json['category_id'] ?? 0 as num).toInt(),
        category: json['category'] is Map<String, dynamic>
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        description: (json['description'] ?? '') as String,
      );
}
