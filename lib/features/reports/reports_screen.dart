import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/stats.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_repository.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_manager.dart';
import 'package:money_tracker_mobile/models/fixed_expense.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/features/budgets/category_budgets_repository.dart';
import 'package:money_tracker_mobile/models/category_budget.dart';
import 'package:money_tracker_mobile/core/category_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _ViewKind { summary, expense, income, budget }

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
  late DateTime _currentMonth;
  _ViewKind _view = _ViewKind.summary;
  int? _touchedIndex;
  late final VoidCallback _monthListener;
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _currentMonth = AppState.instance.currentMonth.value;
    _future = _statsRepo.fetch();
    _monthListener = () {
      final shared = AppState.instance.currentMonth.value;
      if (shared.year == _currentMonth.year && shared.month == _currentMonth.month) {
        return;
      }
      setState(() => _currentMonth = shared);
      _loadDetails();
    };
    AppState.instance.currentMonth.addListener(_monthListener);
    _dataListener = () {
      _loadDetails();
    };
    AppState.instance.dataVersion.addListener(_dataListener);
    _loadDetails();
  }

  String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Map<String, double> _monthTotals() {
    final income = _monthTx
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = _monthTx
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);
    return {'income': income, 'expense': expense};
  }

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
      final now = DateTime.now();
      final isCurrentOrFuture = _currentMonth.year > now.year ||
          (_currentMonth.year == now.year && _currentMonth.month >= now.month);
      if (budgets.isEmpty && isCurrentOrFuture) {
        final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
        final prevBudgets = await _budRepo.listByMonth(prevMonth);
        if (prevBudgets.isNotEmpty) {
          for (final b in prevBudgets) {
            try {
              await _budRepo.create(
                categoryId: b.categoryId,
                year: _currentMonth.year,
                month: _currentMonth.month,
                amount: b.amount,
              );
            } catch (_) {}
          }
          budgets = await _budRepo.listByMonth(_currentMonth);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _monthTx = txs;
      _categoryMap = {for (final c in cats) c.id: c};
      _fixed = fixed;
      _budgets = budgets;
    });
  }

  @override
  void dispose() {
    AppState.instance.currentMonth.removeListener(_monthListener);
    AppState.instance.dataVersion.removeListener(_dataListener);
    super.dispose();
  }

  Future<void> _openBudgetEditor(CategoryBudget budget) async {
    final controller = TextEditingController(
      text: budget.amount.toStringAsFixed(0),
    );
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool saving = false;
        String? error;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final categoryName = budget.category?.name ?? '未分類';
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1A1625), const Color(0xFF0F0B1A)]
                      : [const Color(0xFFFFF5F7), const Color(0xFFF3E5F5)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '予算を編集',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '予算金額',
                          prefixIcon: Icon(Icons.payments_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_rounded, color: Color(0xFFEF5350), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('キャンセル', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final amount = double.tryParse(controller.text.trim());
                                      if (amount == null || amount <= 0) {
                                        setSheetState(() => error = '正しい金額を入力してください');
                                        return;
                                      }
                                      setSheetState(() {
                                        saving = true;
                                        error = null;
                                      });
                                      try {
                                        await _budRepo.update(
                                          budget.id,
                                          categoryId: budget.categoryId,
                                          year: budget.year,
                                          month: budget.month,
                                          amount: amount,
                                        );
                                        AppState.instance.bumpDataVersion();
                                        if (mounted) Navigator.pop(context, true);
                                      } catch (_) {
                                        setSheetState(() => error = '予算の更新に失敗しました');
                                      } finally {
                                        if (mounted) setSheetState(() => saving = false);
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: saving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('保存', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (updated == true && mounted) {
      _loadDetails();
    }
  }

  Future<void> _openFixedExpenseForm({FixedExpense? expense}) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FixedExpenseFormSheet(
        expense: expense,
        repo: _fixRepo,
      ),
    );
    if (updated == true && mounted) {
      _loadDetails();
    }
  }

  Color _parseHex(String hex, {int alpha = 0xFF}) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse(cleaned, radix: 16) ?? 0x999999;
    return Color((alpha << 24) | val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
        final totals = _monthTotals();
        // Aggregate by category (current view)
        final byCategory = <int, double>{};
        if (_view == _ViewKind.expense || _view == _ViewKind.income) {
          final filtered = _monthTx.where((t) =>
              _view == _ViewKind.expense ? t.type == 'expense' : t.type == 'income');
          for (final t in filtered) {
            byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
          }
        }
        final totalSelected = byCategory.values.fold<double>(0, (sum, v) => sum + v);

        final sections = <PieChartSectionData>[];
        final nf = NumberFormat('#,##0', 'ja_JP');
        if (_view == _ViewKind.expense || _view == _ViewKind.income) {
          final entries = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
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
                radius: isTouched ? 58 : 50,
                title: percent >= 5 ? '${percent.toStringAsFixed(0)}%' : '',
                titleStyle: TextStyle(
                  color: Colors.white,
                  fontSize: isTouched ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                titlePositionPercentageOffset: 0.6,
              ),
            );
          }
        }

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
                  // Month selector - 統一サイズ
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
                              AppState.instance
                                  .setCurrentMonth(DateTime(_currentMonth.year, _currentMonth.month - 1));
                            },
                            icon: const Icon(Icons.chevron_left, size: 20),
                            color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, 
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
                              AppState.instance
                                  .setCurrentMonth(DateTime(_currentMonth.year, _currentMonth.month + 1));
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildCuteChip('総計', Icons.summarize_rounded, _view == _ViewKind.summary, () {
                          setState(() { _view = _ViewKind.summary; _touchedIndex = null; });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCuteChip('支出', Icons.arrow_circle_down_rounded, _view == _ViewKind.expense, () {
                          setState(() { _view = _ViewKind.expense; _touchedIndex = null; });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCuteChip('収入', Icons.arrow_circle_up_rounded, _view == _ViewKind.income, () {
                          setState(() { _view = _ViewKind.income; _touchedIndex = null; });
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCuteChip('予算', Icons.account_balance_wallet_rounded, _view == _ViewKind.budget, () {
                          setState(() { _view = _ViewKind.budget; _touchedIndex = null; });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ..._buildTabContent(
                    s: s,
                    monthIncome: totals['income'] ?? 0,
                    monthExpense: totals['expense'] ?? 0,
                    nf: nf,
                    totalSelected: totalSelected,
                    sections: sections,
                    byCategory: byCategory,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCuteChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: isDark
                      ? [color.withOpacity(0.3), color.withOpacity(0.2)]
                      : [color.withOpacity(0.2), color.withOpacity(0.1)],
                )
              : null,
          color: selected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                  color: selected ? color : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child, String? centerText, IconData? icon}) {
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
            Stack(
              alignment: Alignment.center,
              children: [
                child,
                if (centerText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFFE1BEE7).withOpacity(0.3) : const Color(0xFF9C27B0).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      centerText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Map<int, double> byCategory) {
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: entries.map((e) {
        final cat = _categoryMap[e.key];
        final color = cat != null ? _parseHex(cat.color) : Colors.blueGrey;
        final name = cat?.name ?? '未分類';
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${e.value.toStringAsFixed(0)}円',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
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
    final sortedBudgets = [..._budgets]..sort((a, b) => b.amount.compareTo(a.amount));
    final totalBudget = sortedBudgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalSpent = sortedBudgets.fold<double>(0, (sum, b) => sum + b.spent);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '予算合計',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${nf.format(totalSpent)}円 / ${nf.format(totalBudget)}円',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const Divider(height: 16),
        ...sortedBudgets.map((b) {
          final spent = b.spent;
          final budget = b.amount;
          final pct = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
          final over = spent > budget;
          final barColor = over ? Colors.red : Colors.green;
          final categoryName = b.category?.name ?? '未分類';
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openBudgetEditor(b),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
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
          ),
        );
      }),
      ],
    );
  }

  List<Widget> _buildTabContent({
    required Stats s,
    required double monthIncome,
    required double monthExpense,
    required NumberFormat nf,
    required double totalSelected,
    required List<PieChartSectionData> sections,
    required Map<int, double> byCategory,
  }) {
    switch (_view) {
      case _ViewKind.summary:
        return [_buildSummaryCard(s, nf, monthIncome, monthExpense)];
      case _ViewKind.expense:
        return [
          _buildCategoryChartCard(
            title: 'カテゴリ別支出',
            nf: nf,
            totalSelected: totalSelected,
            sections: sections,
            byCategory: byCategory,
          ),
          const SizedBox(height: 16),
          _card(
            title: '固定支出',
            icon: Icons.repeat_rounded,
            child: _buildFixedExpenseList(),
          ),
        ];
      case _ViewKind.income:
        return [
          _buildCategoryChartCard(
            title: 'カテゴリ別収入',
            nf: nf,
            totalSelected: totalSelected,
            sections: sections,
            byCategory: byCategory,
          ),
          const SizedBox(height: 16),
          _card(
            title: '固定収入',
            icon: Icons.repeat_rounded,
            child: _buildFixedIncomeList(),
          ),
        ];
      case _ViewKind.budget:
        return [
          _card(
            title: 'カテゴリ別予算',
            icon: Icons.account_balance_wallet_rounded,
            child: _budgetList(nf),
          ),
        ];
    }
  }

  Widget _buildCategoryChartCard({
    required String title,
    required NumberFormat nf,
    required double totalSelected,
    required List<PieChartSectionData> sections,
    required Map<int, double> byCategory,
  }) {
    return _card(
      title: title,
      icon: title.contains('支出') ? Icons.pie_chart_rounded : Icons.donut_large_rounded,
      centerText: '合計 ${nf.format(totalSelected)}円',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 50,
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
          const SizedBox(height: 16),
          _legend(byCategory),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Stats s, NumberFormat nf, double monthIncome, double monthExpense) {
    return _card(
      title: '今月の総計',
      icon: Icons.summarize_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _metric(
            '収入',
            nf.format(monthIncome),
            const Color(0xFF66BB6A),
            Icons.arrow_circle_up_rounded,
          ),
          const SizedBox(height: 12),
          _metric(
            '支出',
            nf.format(monthExpense),
            const Color(0xFFEF5350),
            Icons.arrow_circle_down_rounded,
          ),
          const SizedBox(height: 12),
          _metric(
            '収支',
            nf.format(monthIncome - monthExpense),
            (monthIncome - monthExpense) >= 0
                ? const Color(0xFF66BB6A)
                : const Color(0xFFEF5350),
            Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFixedIncomeList() {
    final incomes = _fixed.where((f) => f.type == 'income').toList();
    if (incomes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('登録された固定収入がありません',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: incomes
          .map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildFixedExpenseCard(f),
              ))
          .toList(),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withOpacity(0.18), color.withOpacity(0.08)]
              : [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  '$value円',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedExpenseList() {
    final expenses = _fixed.where((f) => f.type == 'expense').toList();
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('登録された固定支出がありません',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: expenses
          .map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildFixedExpenseCard(f),
              ))
          .toList(),
    );
  }

  Widget _buildFixedExpenseCard(FixedExpense f) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = f.type == 'income';
    final amountColor = isIncome ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    final categoryColor = f.category != null
        ? _parseHex(f.category!.color)
        : amountColor;
    final iconData = f.category != null && f.category!.icon.isNotEmpty
        ? CategoryIcons.getIcon(f.category!.icon)
        : CategoryIcons.guessIcon(f.category?.name ?? f.name, f.type);

    final cardGradient = isDark
        ? [const Color(0xFF1A1625).withOpacity(0.95), const Color(0xFF0F0B1A).withOpacity(0.9)]
        : [Colors.white, const Color(0xFFFFF5F7)];
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openFixedExpenseForm(expense: f),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : categoryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(iconData, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (f.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          f.description,
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (f.category?.name != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          f.category!.name,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${f.amount.toStringAsFixed(0)}円',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
