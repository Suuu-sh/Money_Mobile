class SpendingPrediction {
  SpendingPrediction({
    required this.year,
    required this.month,
    required this.currentSpending,
    required this.predictedTotal,
    required this.dailyAverage,
    required this.remainingDays,
    required this.confidence,
    required this.trend,
    required this.weeklyPattern,
    required this.monthlyProgress,
  });

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      year: json['year'] as int,
      month: json['month'] as int,
      currentSpending: (json['currentSpending'] as num).toDouble(),
      predictedTotal: (json['predictedTotal'] as num).toDouble(),
      dailyAverage: (json['dailyAverage'] as num).toDouble(),
      remainingDays: json['remainingDays'] as int,
      confidence: json['confidence'] as String,
      trend: json['trend'] as String,
      weeklyPattern: (json['weeklyPattern'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      monthlyProgress: (json['monthlyProgress'] as num).toDouble(),
    );
  }

  final int year;
  final int month;
  final double currentSpending;
  final double predictedTotal;
  final double dailyAverage;
  final int remainingDays;
  final String confidence;
  final String trend;
  final List<double> weeklyPattern;
  final double monthlyProgress;
}
