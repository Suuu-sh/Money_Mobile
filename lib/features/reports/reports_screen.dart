import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/stats.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
import 'package:money_tracker_mobile/models/category.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _statsRepo = StatsRepository(ApiClient());
  final _txRepo = TransactionsRepository(ApiClient());
  final _catRepo = CategoriesRepository(ApiClient());
  Future<Stats>? _future;
  List<MoneyTransaction> _monthExpenses = [];
  Map<int, Category> _categoryMap = {};
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _future = _statsRepo.fetch();
    _loadDetails();
  }

  String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadDetails() async {
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final txs = await _txRepo.list(
      startDate: _dateStr(start),
      endDate: _dateStr(end),
      type: 'expense',
      pageSize: 500,
    );
    final cats = await _catRepo.list();
    if (!mounted) return;
    setState(() {
      _monthExpenses = txs;
      _categoryMap = {for (final c in cats) c.id: c};
    });
  }

  Color _parseHex(String hex, {int alpha = 0xFF}) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse(cleaned, radix: 16) ?? 0x999999;
    return Color((alpha << 24) | val);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stats>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('読み込みエラー: ${snapshot.error}'));
        }
        final s = snapshot.data!;
        // Aggregate by category (expense only)
        final byCategory = <int, double>{};
        for (final t in _monthExpenses) {
          byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
        }
        final totalExpense = byCategory.values.fold<double>(0, (sum, v) => sum + v);

        final sections = <PieChartSectionData>[];
        byCategory.forEach((id, amount) {
          if (amount <= 0) return;
          final c = _categoryMap[id];
          final color = c != null ? _parseHex(c.color) : Colors.blueGrey;
          sections.add(PieChartSectionData(color: color, value: amount, title: '', radius: 44));
        });

        // Monthly total pie (expense vs income)
        final expVsIncome = [
          PieChartSectionData(color: Colors.redAccent, value: s.thisMonthExpense <= 0 ? 0.01 : s.thisMonthExpense, title: '', radius: 44),
          PieChartSectionData(color: Colors.green, value: s.thisMonthIncome <= 0 ? 0.01 : s.thisMonthIncome, title: '', radius: 44),
        ];

        return SafeArea(
          top: true,
          bottom: false,
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('レポート', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // 円グラフ1: 月の総計（支出/収入）
              _card(
                title: '今月の総計（支出/収入）',
                centerText: '支出 ${s.thisMonthExpense.toStringAsFixed(0)}',
                child: SizedBox(
                  height: 160,
                  child: PieChart(PieChartData(sections: expVsIncome, sectionsSpace: 0, centerSpaceRadius: 42)),
                ),
              ),

              const SizedBox(height: 16),

              // 円グラフ2: カテゴリ別の合計（支出）
              _card(
                title: 'カテゴリ別支出',
                centerText: '合計 ${totalExpense.toStringAsFixed(0)}',
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(sections: sections, sectionsSpace: 0, centerSpaceRadius: 40)),
                    ),
                    const SizedBox(height: 8),
                    _legend(byCategory),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _card({required String title, required Widget child, String? centerText}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                child,
                if (centerText != null)
                  Text(centerText, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Map<int, double> byCategory) {
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: entries.map((e) {
        final cat = _categoryMap[e.key];
        final color = cat != null ? _parseHex(cat.color) : Colors.blueGrey;
        final name = cat?.name ?? '未分類';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(name)),
              Text(e.value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
