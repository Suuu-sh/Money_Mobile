import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
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

  Stats? _stats;
  List<MoneyTransaction> _monthTx = [];
  Map<int, Category> _catMap = {};
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final results = await Future.wait([
      _statsRepo.fetch(),
      _txRepo.list(startDate: _dateStr(start), endDate: _dateStr(end), pageSize: 1000),
      _catRepo.list(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as Stats;
      _monthTx = results[1] as List<MoneyTransaction>;
      final cats = results[2] as List<Category>;
      _catMap = {for (final c in cats) c.id: c};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _stats!;
    final nf = NumberFormat('#,##0', 'ja_JP');

    final now = DateTime.now();
    final totalDays = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final passed = (now.year == _currentMonth.year && now.month == _currentMonth.month) ? now.day : totalDays;

    final monthExpense = _monthTx.where((t) => t.type == 'expense').fold<double>(0, (sum, t) => sum + t.amount);
    final avgPerDay = passed == 0 ? 0 : monthExpense / passed;
    final forecastExpense = (avgPerDay * totalDays);
    final forecastBalance = s.thisMonthIncome - forecastExpense;

    final byCat = <int, double>{};
    for (final t in _monthTx.where((t) => t.type == 'expense')) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final topCats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 直近比較などの追加分析はここに拡張可能

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Header month switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1); }); _load(); },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(DateFormat('yyyy/MM').format(_currentMonth), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1); }); _load(); },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 4),
            _card(
              title: '今月の支出予測',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metric('現在の支出', nf.format(monthExpense), Colors.redAccent),
                  const SizedBox(height: 6),
                  _metric('予測支出（${totalDays}日間）', nf.format(forecastExpense), Colors.orangeAccent),
                  const SizedBox(height: 6),
                  _metric('予測収支', nf.format(forecastBalance), forecastBalance >= 0 ? Colors.green : Colors.red),
                  const SizedBox(height: 6),
                  Text('平均: ${nf.format(avgPerDay)} /日・残り${(totalDays - passed).clamp(0, totalDays)}日'),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _card(
              title: 'カテゴリ別ハイライト',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...topCats.take(3).map((e) {
                    final cat = _catMap[e.key];
                    final name = cat?.name ?? '未分類';
                    final percent = (byCat.values.isEmpty) ? 0 : (e.value / byCat.values.reduce((a, b) => a + b) * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _parseHex(cat?.color ?? '#999999'), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name)),
                          Text('${nf.format(e.value)}（${percent.toStringAsFixed(0)}%）', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                  if (topCats.isEmpty) const Text('データがありません', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            // ヒントカードは削除
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Color _parseHex(String hex, {int alpha = 0xFF}) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse(cleaned, radix: 16) ?? 0x999999;
    return Color((alpha << 24) | val);
  }

}
