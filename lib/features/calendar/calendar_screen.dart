import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/transaction.dart';

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
          // Weekday header (with side padding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekdays
                  .map((label) => Expanded(child: Center(child: Text(label, style: const TextStyle(color: Colors.grey)))))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Calendar grid (edge-to-edge)
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
          else
            _buildCalendarGrid(edgeToEdge: true, shrinkWrap: true),

          // Day transactions list (with side padding)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDate == null
                    ? '取引'
                    : DateFormat('yyyy/MM/dd（E）', 'ja').format(_selectedDate!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDayTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid({bool edgeToEdge = false, bool shrinkWrap = false}) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Monday-first weekday index (Mon=0..Sun=6)
    final firstWeekday = (firstDay.weekday + 6) % 7;
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

      return InkWell(
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          margin: edgeToEdge ? EdgeInsets.zero : const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isSameDay(_selectedDate, date) ? Colors.green.withOpacity(0.06) : null,
            border: Border.all(
              color: _isSameDay(_selectedDate, date) ? Colors.green : Colors.grey.shade300,
              width: edgeToEdge ? 0.5 : 1,
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
                  color: isCurrent ? Colors.black : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              // Show total daily expense prominently
              if (expense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${expense.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              if (expense == 0)
                Text('—', style: TextStyle(color: isCurrent ? Colors.grey.shade400 : Colors.grey.shade300, fontSize: 10)),
            ],
          ),
        ),
      );
    });

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 0.95,
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
}
