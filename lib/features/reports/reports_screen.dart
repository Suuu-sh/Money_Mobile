import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/stats.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_repository.dart';
import 'package:money_tracker_mobile/models/fixed_expense.dart';
import 'package:money_tracker_mobile/models/category.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _ViewKind { expense, income, budget }

class _ReportsScreenState extends State<ReportsScreen> {
  final _statsRepo = StatsRepository(ApiClient());
  final _txRepo = TransactionsRepository(ApiClient());
  final _fixRepo = FixedExpensesRepository(ApiClient());
  final _catRepo = CategoriesRepository(ApiClient());
  final _budRepo = CategoryBudgetsRepository(ApiClient());
  Future<Stats>? _future;
  List<MoneyTransaction> _monthTx = [];
  List<FixedExpense> _fixed = [];
  Map<int, Category> _categoryMap = {};
  List<CategoryBudget> _budgets = [];
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _ViewKind _view = _ViewKind.expense;
  int? _touchedIndex;

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
      pageSize: 1000,
    );
    final cats = await _catRepo.list();
    // 固定費も読み込む
    List<FixedExpense> fixed = [];
    try {
      fixed = await _fixRepo.list();
    } catch (_) {}
    // カテゴリ予算
    List<CategoryBudget> budgets = [];
    try {
      budgets = await _budRepo.listByMonth(_currentMonth);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _monthTx = txs;
      _categoryMap = {for (final c in cats) c.id: c};
      _fixed = fixed;
      _budgets = budgets;
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
        // Aggregate by category (current view)
        final byCategory = <int, double>{};
        for (final t in _monthTx.where((t) => (_view == _ViewKind.expense ? t.type == 'expense' : t.type == 'income'))) {
          byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
        }
        final totalSelected = byCategory.values.fold<double>(0, (sum, v) => sum + v);

        final sections = <PieChartSectionData>[];
        final nf = NumberFormat('#,##0', 'ja_JP');
        final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        for (var i = 0; i < entries.length; i++) {
          final id = entries[i].key;
          final amount = entries[i].value;
          if (amount <= 0) continue;
          final c = _categoryMap[id];
          final color = c != null ? _parseHex(c.color) : Colors.blueGrey;
          final isTouched = _touchedIndex == i;
          final percent = totalSelected == 0 ? 0 : (amount / totalSelected * 100);
          sections.add(
            PieChartSectionData(
              color: color,
              value: amount,
              radius: isTouched ? 52 : 44,
              title: percent >= 5 ? '${percent.toStringAsFixed(0)}%' : '',
              titleStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: isTouched ? 12 : 10,
                fontWeight: FontWeight.w600,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
          );
        }

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
              // Month selector + toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1); }); _loadDetails(); }, icon: const Icon(Icons.chevron_left)),
                  Text(DateFormat('yyyy/MM').format(_currentMonth), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1); }); _loadDetails(); }, icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: _view == _ViewKind.expense,
                    onSelected: (_) => setState(() { _view = _ViewKind.expense; _touchedIndex = null; }),
                  ),
                  ChoiceChip(
                    label: const Text('収入'),
                    selected: _view == _ViewKind.income,
                    onSelected: (_) => setState(() { _view = _ViewKind.income; _touchedIndex = null; }),
                  ),
                  ChoiceChip(
                    label: const Text('予算'),
                    selected: _view == _ViewKind.budget,
                    onSelected: (_) => setState(() { _view = _ViewKind.budget; _touchedIndex = null; }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 今月の総計（数字表示）- 固定費も集計に含める
              _card(
                title: '今月の総計',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: _metric(
                        '収入',
                        nf.format(
                          s.thisMonthIncome + _fixed.where((f) => f.type == 'income').fold<double>(0, (sum, f) => sum + f.amount),
                        ),
                        Colors.green,
                      )),
                      Expanded(child: _metric(
                        '支出',
                        nf.format(
                          s.thisMonthExpense + _fixed.where((f) => f.type == 'expense').fold<double>(0, (sum, f) => sum + f.amount),
                        ),
                        Colors.red,
                      )),
                      Expanded(child: _metric(
                        '収支',
                        nf.format(
                          (s.thisMonthIncome + _fixed.where((f) => f.type == 'income').fold<double>(0, (sum, f) => sum + f.amount)) -
                          (s.thisMonthExpense + _fixed.where((f) => f.type == 'expense').fold<double>(0, (sum, f) => sum + f.amount)),
                        ),
                        ((s.thisMonthIncome + _fixed.where((f) => f.type == 'income').fold<double>(0, (sum, f) => sum + f.amount)) -
                         (s.thisMonthExpense + _fixed.where((f) => f.type == 'expense').fold<double>(0, (sum, f) => sum + f.amount))) >= 0
                          ? Colors.green
                          : Colors.red,
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_view == _ViewKind.budget)
                _card(
                  title: 'カテゴリ別予算',
                  child: _budgetList(nf),
                )
              else
                _card(
                  title: _view == _ViewKind.expense ? 'カテゴリ別支出' : 'カテゴリ別収入',
                  centerText: '合計 ${nf.format(totalSelected)}円',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                                  setState(() => _touchedIndex = null);
                                } else {
                                  setState(() => _touchedIndex = response.touchedSection!.touchedSectionIndex);
                                }
                              },
                            ),
                          ),
                        ),
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
              Text('${e.value.toStringAsFixed(0)}円', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _budgetList(NumberFormat nf) {
    if (_budgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('予算データがありません', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: _budgets.map((b) {
        final spent = b.actualAmount;
        final budget = b.budgetAmount;
        final pct = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
        final over = spent > budget;
        final barColor = over ? Colors.red : Colors.green;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(b.categoryName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${nf.format(spent)}円 / ${nf.format(budget)}円', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  color: barColor,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _metric(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(
          '$value円',
          style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
