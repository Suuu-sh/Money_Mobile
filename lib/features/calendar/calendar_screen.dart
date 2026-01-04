import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/transaction.dart';
import 'package:money_tracker_mobile/features/transactions/transaction_edit_sheet.dart';
import 'package:money_tracker_mobile/core/category_icons.dart';
import 'package:money_tracker_mobile/features/input/input_screen.dart';
// import removed: input is opened from global FAB

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TransactionsRepository(ApiClient());
  late DateTime _currentMonth;
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;
  static const _weekdays = ['月','火','水','木','金','土','日'];
  DateTime? _selectedDate;
  bool _startMonday = true;
  late final VoidCallback _monthListener;
  final Map<String, DateTime> _selectedDays = {};

  void _setSelectedDate(DateTime date) {
    final key = _monthKey(date);
    _selectedDays[key] = date;
    AppState.instance.updateQuickEntryDate(date);
    setState(() => _selectedDate = date);
  }

  String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _currentMonth = AppState.instance.currentMonth.value;
    _load();
    _loadPrefs();
    AppState.instance.dataVersion.addListener(_onDataChanged);
    _monthListener = () {
      final shared = AppState.instance.currentMonth.value;
      if (shared.year == _currentMonth.year && shared.month == _currentMonth.month) {
        return;
      }
      setState(() => _currentMonth = shared);
      _load();
    };
    AppState.instance.currentMonth.addListener(_monthListener);
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
        final key = _monthKey(_currentMonth);
        final saved = _selectedDays[key];
        DateTime resolved;
        if (saved != null && saved.year == _currentMonth.year && saved.month == _currentMonth.month) {
          resolved = saved;
        } else if (_selectedDate != null &&
            _selectedDate!.year == _currentMonth.year &&
            _selectedDate!.month == _currentMonth.month) {
          resolved = _selectedDate!;
        } else {
          final now = DateTime.now();
          if (now.year == _currentMonth.year && now.month == _currentMonth.month) {
            resolved = DateTime(now.year, now.month, now.day);
          } else {
            resolved = start;
          }
          _selectedDays[key] = resolved;
        }
        _selectedDate = resolved;
      });
      if (_selectedDate != null) {
        AppState.instance.updateQuickEntryDate(_selectedDate!);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    AppState.instance.setCurrentMonth(DateTime(_currentMonth.year, _currentMonth.month - 1));
  }

  void _nextMonth() {
    AppState.instance.setCurrentMonth(DateTime(_currentMonth.year, _currentMonth.month + 1));
  }

  void _onDataChanged() {
    // reload current month data when something changed elsewhere
    _load();
  }

  @override
  void dispose() {
    AppState.instance.dataVersion.removeListener(_onDataChanged);
    AppState.instance.currentMonth.removeListener(_monthListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final borderColor = theme.colorScheme.outlineVariant;
    final selectedBorder = theme.colorScheme.primary;
    final selectedBg = theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.06);
    final weekdayStyle = TextStyle(
      color: isDark ? const Color(0xFFB4A5D9) : const Color(0xFF9575CD),
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );
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
        child: Column(
          children: [
            // Header with cute styling - 統一サイズ
            _buildMonthHeader(context, isDark),
            // Weekday header - 縦幅を小さく
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: (_startMonday ? _weekdays : ['日','月','火','水','木','金','土'])
                    .map((label) => Expanded(child: Center(child: Text(label, style: weekdayStyle))))
                    .toList(),
              ),
            ),

            // Calendar grid with swipe
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    _prevMonth();
                  } else if (details.primaryVelocity! < 0) {
                    _nextMonth();
                  }
                },
                child: _buildCalendarGrid(edgeToEdge: true, shrinkWrap: true),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildMonthlyNetSummary(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSelectedDateLabel(context),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (_selectedDate == null) return;
                    if (details.primaryVelocity! > 0) {
                      // 前の日
                      _setSelectedDate(_selectedDate!.subtract(const Duration(days: 1)));
                    } else if (details.primaryVelocity! < 0) {
                      // 次の日
                      _setSelectedDate(_selectedDate!.add(const Duration(days: 1)));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDayTransactionsList(),
                  ),
                ),
              ),
            ],
          ],
        ),
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
      final mainColor = isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0);
      final isSelected = _isSameDay(_selectedDate, date);
      final gridColor = isSelected ? mainColor.withOpacity(0.6) : theme.colorScheme.outlineVariant;
      final col = i % 7;
      final row = i ~/ 7;
      final totalRows = (totalCells / 7).ceil();
      final isFirstCol = col == 0;
      final isLastCol = col == 6;
      final isLastRow = row == totalRows - 1;

      return AspectRatio(
        aspectRatio: 1,
        child: InkWell(
          onTap: () => _setSelectedDate(date),
          onLongPress: () async {
            _setSelectedDate(date);
            final added = await _openAddTransaction(date);
            if (added == true) {
              _load();
            }
          },
          child: Container(
            margin: edgeToEdge ? EdgeInsets.zero : const EdgeInsets.all(2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: isDark
                          ? [mainColor.withOpacity(0.16), mainColor.withOpacity(0.08)]
                          : [mainColor.withOpacity(0.1), mainColor.withOpacity(0.04)],
                    )
                  : null,
              border: Border(
                left: BorderSide(
                  color: isFirstCol ? Colors.transparent : gridColor,
                  width: isFirstCol ? 0 : (edgeToEdge ? 0.5 : 1),
                ),
                right: BorderSide(
                  color: isLastCol ? Colors.transparent : gridColor,
                  width: isLastCol ? 0 : (edgeToEdge ? 0.5 : 1),
                ),
                top: BorderSide(
                  color: row == 0 ? gridColor : gridColor.withOpacity(0.7),
                  width: edgeToEdge ? 0.5 : 1,
                ),
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
                    fontSize: 11,
                    color: isCurrent
                        ? Theme.of(context).colorScheme.onSurface
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 1),
                if (income > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${income.toStringAsFixed(0)}円',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300
                            : Colors.green.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (expense > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${expense.toStringAsFixed(0)}円',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1,
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

  Widget _buildMonthHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left, size: 20),
              color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, 
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
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right, size: 20),
              color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget metric(String label, String value, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                : [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: isDark ? color.withOpacity(0.9) : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$value円',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: metric('収入', nf.format(income), const Color(0xFF66BB6A), Icons.arrow_circle_up_rounded)),
        const SizedBox(width: 6),
        Expanded(child: metric('支出', nf.format(expense), const Color(0xFFEF5350), Icons.arrow_circle_down_rounded)),
        const SizedBox(width: 6),
        Expanded(child: metric('収支', nf.format(net), net >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), Icons.account_balance_wallet_rounded)),
      ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'この日に記録された取引はありません',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    final nf = NumberFormat('#,##0', 'ja_JP');
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final t = items[index];
        final isIncome = t.type == 'income';
        final sign = isIncome ? '+' : '-';
        // カテゴリの色とアイコンを取得
        final categoryColor = t.category != null 
            ? _parseHex(t.category!.color)
            : (isIncome ? const Color(0xFF66BB6A) : const Color(0xFFEF5350));
        final categoryIcon = t.category != null && t.category!.icon.isNotEmpty
            ? CategoryIcons.getIcon(t.category!.icon)
            : CategoryIcons.guessIcon(t.category?.name ?? '', t.type);
        final cardGradientColors = isDark
            ? [const Color(0xFF1A1625).withOpacity(0.95), const Color(0xFF0F0B1A).withOpacity(0.9)]
            : [const Color(0xFFFFF5F7), const Color(0xFFF3E5F5)];
        final cardBorderColor = isDark
            ? const Color(0xFFE1BEE7).withOpacity(0.2)
            : const Color(0xFF9C27B0).withOpacity(0.2);
        final iconContainerColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95);
        final iconBorderColor = isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF9C27B0).withOpacity(0.3);
        final amountColor = isIncome ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardGradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final updated = await _openEditTransaction(t);
              if (updated == true) _load();
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconContainerColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconBorderColor, width: 1.5),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.category?.name ?? '(カテゴリ不明)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: categoryColor,
                          ),
                        ),
                        if (t.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              t.description,
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign${nf.format(t.amount)}円',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _openEditTransaction(MoneyTransaction t) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TransactionEditSheet(transaction: t),
    );
  }

  Future<bool?> _openAddTransaction(DateTime date) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => InputScreen(initialDate: date),
    );
  }

  // Build selected date label with cute styling
  Widget _buildSelectedDateLabel(BuildContext context) {
    if (_selectedDate == null) {
      return const Text('取引', style: TextStyle(fontWeight: FontWeight.bold));
    }
    final d = _selectedDate!;
    final main = DateFormat('yyyy/MM/dd', 'ja').format(d);
    final week = DateFormat('E', 'ja').format(d);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          Icons.event_note_rounded,
          size: 16,
          color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
            ),
            children: [
              TextSpan(text: main),
              TextSpan(
                text: ' ($week)',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseHex(String hex, {int alpha = 0xFF}) {
    final cleaned = hex.replaceFirst('#', '');
    final val = int.tryParse(cleaned, radix: 16) ?? 0x999999;
    return Color((alpha << 24) | val);
  }

}
