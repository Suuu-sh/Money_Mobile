class Stats {
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;
  final double thisMonthIncome;
  final double thisMonthExpense;
  final int transactionCount;

  Stats({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
    required this.thisMonthIncome,
    required this.thisMonthExpense,
    required this.transactionCount,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpense: (json['totalExpense'] as num).toDouble(),
        currentBalance: (json['currentBalance'] as num).toDouble(),
        thisMonthIncome: (json['thisMonthIncome'] as num).toDouble(),
        thisMonthExpense: (json['thisMonthExpense'] as num).toDouble(),
        transactionCount: (json['transactionCount'] as num).toInt(),
      );
}

