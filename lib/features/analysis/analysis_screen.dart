import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/analysis/analysis_repository.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/spending_prediction.dart';
import 'package:money_tracker_mobile/models/stats.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
import 'package:money_tracker_mobile/models/category.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _statsRepo = StatsRepository(ApiClient());
  final _txRepo = TransactionsRepository(ApiClient());
  final _catRepo = CategoriesRepository(ApiClient());
  final _analysisRepo = AnalysisRepository(ApiClient());

  Stats? _stats;
  List<MoneyTransaction> _monthTx = [];
  Map<int, Category> _catMap = {};
  late DateTime _currentMonth;
  bool _loading = true;
  SpendingPrediction? _prediction;
  late final VoidCallback _monthListener;

  @override
  void initState() {
    super.initState();
    _currentMonth = AppState.instance.currentMonth.value;
    _monthListener = () {
      final shared = AppState.instance.currentMonth.value;
      if (shared.year == _currentMonth.year && shared.month == _currentMonth.month) {
        return;
      }
      setState(() => _currentMonth = shared);
      _load();
    };
    AppState.instance.currentMonth.addListener(_monthListener);
    _load();
  }

  @override
  void dispose() {
    AppState.instance.currentMonth.removeListener(_monthListener);
    super.dispose();
  }

  String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _prediction = null;
    });
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final results = await Future.wait([
      _statsRepo.fetch(),
      _txRepo.list(
          startDate: _dateStr(start), endDate: _dateStr(end), pageSize: 1000),
      _catRepo.list(),
      _analysisRepo.fetchSpendingPrediction(
          year: _currentMonth.year, month: _currentMonth.month),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as Stats;
      _monthTx = results[1] as List<MoneyTransaction>;
      final cats = results[2] as List<Category>;
      _catMap = {for (final c in cats) c.id: c};
      _prediction = results[3] as SpendingPrediction;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_loading || _stats == null || _prediction == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _stats!;
    final nf = NumberFormat('#,##0', 'ja_JP');

    final prediction = _prediction!;
    final totalDays =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final forecastBalance = s.thisMonthIncome - prediction.predictedTotal;

    final byCat = <int, double>{};
    for (final t in _monthTx.where((t) => t.type == 'expense')) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final topCats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1625), const Color(0xFF0F0B1A)]
              : [const Color(0xFFFFF5F7), const Color(0xFFF3E5F5)],
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Header month switcher - 統一サイズ
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          AppState.instance.setCurrentMonth(
                            DateTime(_currentMonth.year, _currentMonth.month - 1),
                          );
                        },
                        icon: const Icon(Icons.chevron_left, size: 20),
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.insights_rounded, 
                          size: 16, 
                          color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('yyyy年 MM月').format(_currentMonth),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          AppState.instance.setCurrentMonth(
                            DateTime(_currentMonth.year, _currentMonth.month + 1),
                          );
                        },
                        icon: const Icon(Icons.chevron_right, size: 20),
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _card(
                title: '今月の支出予測',
                icon: Icons.trending_up_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metric('現在の支出', nf.format(prediction.currentSpending),
                        const Color(0xFFEF5350), Icons.shopping_cart_rounded),
                    const SizedBox(height: 10),
                    _metric(
                        '予測支出（${totalDays}日間）',
                        nf.format(prediction.predictedTotal),
                        const Color(0xFFFF9800), Icons.auto_graph_rounded),
                    const SizedBox(height: 10),
                    _metric('予測収支', nf.format(forecastBalance),
                        forecastBalance >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 12),
                    _infoRow(Icons.calendar_month_rounded, '月の進捗: ${prediction.monthlyProgress.toStringAsFixed(0)}%'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.show_chart_rounded,
                      '平均: ${nf.format(prediction.dailyAverage)}円/日・残り${prediction.remainingDays}日・精度: ${_confidenceLabel(prediction.confidence)}',
                    ),
                    const SizedBox(height: 6),
                    _infoRow(Icons.timeline_rounded, '傾向: ${_trendLabel(prediction.trend)}'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _card(
                title: 'カテゴリ別ハイライト',
                icon: Icons.pie_chart_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...topCats.take(3).map((e) {
                      final cat = _catMap[e.key];
                      final name = cat?.name ?? '未分類';
                      final color = _parseHex(cat?.color ?? '#999999');
                      final percent = (byCat.values.isEmpty)
                          ? 0
                          : (e.value /
                              byCat.values.reduce((a, b) => a + b) *
                              100);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '${nf.format(e.value)}円（${percent.toStringAsFixed(0)}%）',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (topCats.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'データがありません',
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child, IconData? icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF9C27B0).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withOpacity(0.2), color.withOpacity(0.1)]
              : [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? color.withOpacity(0.9) : color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value円',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _confidenceLabel(String value) {
    switch (value) {
      case 'high':
        return '高精度';
      case 'medium':
        return '中精度';
      default:
        return '低精度';
    }
  }

  String _trendLabel(String value) {
    switch (value) {
      case 'increasing':
        return '増加傾向';
      case 'decreasing':
        return '減少傾向';
      default:
        return '安定';
    }
  }

  Color _parseHex(String hex, {int alpha = 0xFF}) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse(cleaned, radix: 16) ?? 0x999999;
    return Color((alpha << 24) | val);
  }
}
