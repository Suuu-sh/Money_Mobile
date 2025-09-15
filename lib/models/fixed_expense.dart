class FixedExpense {
  final int id;
  final String name;
  final double amount;
  final String type; // 'expense' or 'income'

  FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
  });

  factory FixedExpense.fromJson(Map<String, dynamic> json) => FixedExpense(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        amount: (json['amount'] as num).toDouble(),
        type: (json['type'] ?? 'expense') as String,
      );
}

