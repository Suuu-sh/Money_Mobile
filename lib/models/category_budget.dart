import 'package:money_tracker_mobile/models/category.dart';

class CategoryBudget {
  final int id;
  final int categoryId;
  final Category? category;
  final int year;
  final int month;
  final double amount;
  final double spent;
  final double remaining;
  final double utilizationRate;

  CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.year,
    required this.month,
    required this.amount,
    required this.spent,
    required this.remaining,
    required this.utilizationRate,
  });

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return CategoryBudget(
      id: (json['id'] ?? 0 as num).toInt(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? 0 as num).toInt(),
      category: categoryJson is Map<String, dynamic>
          ? Category.fromJson(categoryJson)
          : null,
      year: (json['year'] ?? 0 as num).toInt(),
      month: (json['month'] ?? 0 as num).toInt(),
      amount: (json['amount'] ?? json['budgetAmount'] ?? 0).toDouble(),
      spent: (json['spent'] ?? json['actualAmount'] ?? json['spentAmount'] ?? 0)
          .toDouble(),
      remaining: (json['remaining'] ?? json['remainingAmount'] ?? 0).toDouble(),
      utilizationRate:
          (json['utilizationRate'] ?? json['budgetUtilization'] ?? 0).toDouble(),
    );
  }
}
