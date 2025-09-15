import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
// import removed: input is opened from global FAB

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TransactionsRepository(ApiClient());
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;
  static const _weekdays = ['月','火','水','木','金','土','日'];
  DateTime? _selectedDate;
  bool _startMonday = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  String _dateStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _startMonday = prefs.getBool('startMonday') ?? true);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    try {
      final list = await _repo.list(
        startDate: _dateStr(start),
        endDate: _dateStr(end),
        pageSize: 200,
      );
      setState(() {
        _transactions = list;
        // keep selection inside the new month
        _selectedDate ??= DateTime.now();
        if (_selectedDate!.year != _currentMonth.year || _selectedDate!.month != _currentMonth.month) {
          _selectedDate = start;
        }
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final borderColor = theme.colorScheme.outlineVariant; // align to frontend slate tone
    final selectedBorder = theme.colorScheme.primary;
    final selectedBg = theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06);
    final weekdayStyle = TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          // Header (with side padding)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(DateFormat('yyyy/MM').format(_currentMonth), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          // Weekday header (edge-to-edge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (_startMonday ? _weekdays : ['日','月','火','水','木','金','土'])
                .map((label) => Expanded(child: Center(child: Text(label, style: weekdayStyle))))
                .toList(),
          ),
          const SizedBox(height: 6),

          // Scrollable content area to prevent bottom overflow
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar grid (edge-to-edge)
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                  else
                    _buildCalendarGrid(edgeToEdge: true, shrinkWrap: true),

                  // Monthly net summary (between calendar and daily transactions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildMonthlyNetSummary(context),
                  ),

                  // Day transactions list (with side padding)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSelectedDateLabel(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDayTransactionsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid({bool edgeToEdge = false, bool shrinkWrap = false}) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Monday-first weekday index (Mon=0..Sun=6)
    final firstWeekday = _startMonday ? ((firstDay.weekday + 6) % 7) : (firstDay.weekday % 7);
    final daysInMonth = lastDay.day;
    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7; // round up to full weeks

    final cells = List<Widget>.generate(totalCells, (i) {
      final dayNum = i - firstWeekday + 1;
      // その月の範囲外も DateTime の繰り上げ/繰り下げに任せて表示（前月・翌月の数字を埋める）
      final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
      final isCurrent = date.month == _currentMonth.month;
      final dayTx = _transactions.where((t) {
        final d = t.date.toLocal();
        return d.year == date.year && d.month == date.month && d.day == date.day;
      }).toList();

      final income = dayTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
      final expense = dayTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final gridColor = _isSameDay(_selectedDate, date)
          ? theme.colorScheme.primary
          : theme.colorScheme.outlineVariant;
      final col = i % 7;
      final row = i ~/ 7;
      final totalRows = (totalCells / 7).ceil();
      final isFirstCol = col == 0;
      final isLastCol = col == 6;
      final isLastRow = row == totalRows - 1;

      return InkWell(
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          margin: edgeToEdge ? EdgeInsets.zero : const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isSameDay(_selectedDate, date)
                ? theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06)
                : null,
            border: Border(
              // 左右外枠は消す（内部線のみ）
              left: BorderSide(
                color: isFirstCol ? Colors.transparent : gridColor,
                width: isFirstCol ? 0 : (edgeToEdge ? 0.5 : 1),
              ),
              right: BorderSide(
                color: isLastCol ? Colors.transparent : gridColor,
                width: isLastCol ? 0 : (edgeToEdge ? 0.5 : 1),
              ),
              // 上端は1行目のみ描画して外枠を作る
              top: BorderSide(
                color: row == 0 ? gridColor : Colors.transparent,
                width: row == 0 ? (edgeToEdge ? 0.5 : 1) : 0,
              ),
              // 下端は最終行も含めて描画（外枠を出す）。内部線も維持
              bottom: BorderSide(
                color: gridColor,
                width: edgeToEdge ? 0.5 : 1,
              ),
            ),
            borderRadius: edgeToEdge ? BorderRadius.zero : BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isCurrent ? Theme.of(context).colorScheme.onSurface : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 2),
              // Show both income (green) and expense (red) if they exist.
              if (income > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    income.toStringAsFixed(0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              if (expense > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      expense.toStringAsFixed(0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (expense == 0 && income == 0)
                const SizedBox.shrink(),
            ],
          ),
        ),
      );
    });

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 0.90,
      mainAxisSpacing: edgeToEdge ? 0 : 4,
      crossAxisSpacing: edgeToEdge ? 0 : 4,
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
      children: cells,
    );
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMonthlyNetSummary(BuildContext context) {
    // Compute monthly totals from currently loaded transactions
    double income = 0, expense = 0;
    for (final t in _transactions) {
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }
    final net = income - expense;
    final nf = NumberFormat('#,##0', 'ja_JP');

    Widget metric(String label, String value, Color color) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: metric('収入', nf.format(income), Colors.green)),
            Expanded(child: metric('支出', nf.format(expense), Colors.red)),
            Expanded(child: metric('総収支', nf.format(net), net >= 0 ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTransactionsList() {
    final date = _selectedDate;
    if (date == null) {
      return const SizedBox.shrink();
    }
    final items = _transactions.where((t) {
      final d = t.date.toLocal();
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();

    if (items.isEmpty) {
      return const Text('この日に記録された取引はありません', style: TextStyle(color: Colors.grey));
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final t = items[i];
          final sign = t.type == 'income' ? '+' : '-';
          final color = t.type == 'income' ? Colors.green : Colors.red;
          return ListTile(
            dense: true,
            title: Text(t.category?.name ?? '(カテゴリ不明)'),
            subtitle: Text(t.description.isEmpty ? '' : t.description),
            trailing: Text(
              '$sign${t.amount.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // Build selected date label with gray parentheses in dark theme
  Widget _buildSelectedDateLabel(BuildContext context) {
    if (_selectedDate == null) {
      return const Text('取引', style: TextStyle(fontWeight: FontWeight.bold));
    }
    final d = _selectedDate!;
    final main = DateFormat('yyyy/MM/dd', 'ja').format(d);
    final week = DateFormat('E', 'ja').format(d);
    final baseStyle = const TextStyle(fontWeight: FontWeight.bold);
    final parenStyle = baseStyle.copyWith(color: Colors.grey);
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(baseStyle),
        children: [
          TextSpan(text: main),
          TextSpan(text: '（', style: parenStyle),
          TextSpan(text: week),
          TextSpan(text: '）', style: parenStyle),
        ],
      ),
    );
  }
}
