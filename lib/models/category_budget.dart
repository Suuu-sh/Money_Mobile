class CategoryBudget {
  final int id;
  final int categoryId;
  final String categoryName;
  final double budgetAmount;
  final double actualAmount;

  CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.actualAmount,
  });

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      id: (json['id'] ?? 0 as num).toInt(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? 0 as num).toInt(),
      categoryName: (json['categoryName'] ?? json['category_name'] ?? json['name'] ?? '') as String,
      budgetAmount: (json['budgetAmount'] ?? json['budget_amount'] ?? 0).toDouble(),
      actualAmount: (json['actualAmount'] ?? json['actual_amount'] ?? 0).toDouble(),
    );
  }
}

