import 'dart:math';

import 'package:intl/intl.dart';

class MockServer {
  static final MockServer _instance = MockServer._();
  factory MockServer() => _instance;
  MockServer._() {
    _seed();
  }

  final List<Map<String, dynamic>> _categories = [];
  final List<Map<String, dynamic>> _transactions = [];

  void _seed() {
    if (_categories.isNotEmpty) return;
    int id = 1;
    // Expense categories
    _categories.addAll([
      {
        'id': id++, 'userId': 1, 'name': '食費', 'type': 'expense', 'color': '#EF4444', 'icon': '🍙', 'description': '食品・外食'
      },
      {
        'id': id++, 'userId': 1, 'name': '日用品', 'type': 'expense', 'color': '#F59E0B', 'icon': '🧻', 'description': '日用雑貨'
      },
      {
        'id': id++, 'userId': 1, 'name': '交通', 'type': 'expense', 'color': '#3B82F6', 'icon': '🚃', 'description': '電車・バス'
      },
      {
        'id': id++, 'userId': 1, 'name': '住居', 'type': 'expense', 'color': '#8B5CF6', 'icon': '🏠', 'description': '家賃・住宅'
      },
    ]);
    // Income categories
    _categories.addAll([
      {
        'id': id++, 'userId': 1, 'name': '給与', 'type': 'income', 'color': '#10B981', 'icon': '💼', 'description': '給料'
      },
      {
        'id': id++, 'userId': 1, 'name': '副収入', 'type': 'income', 'color': '#06B6D4', 'icon': '💡', 'description': '副業・配当'
      },
    ]);

    // Seed transactions for current month
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final rnd = Random(42);
    for (int i = 0; i < 20; i++) {
      final day = start.add(Duration(days: rnd.nextInt(28)));
      final isIncome = rnd.nextBool() && i % 5 == 0; // fewer incomes
      final cat = _categories.where((c) => c['type'] == (isIncome ? 'income' : 'expense')).toList()[rnd.nextInt(isIncome ? 2 : 4)];
      final amount = isIncome ? (3000 + rnd.nextInt(7000)) : (300 + rnd.nextInt(3000));
      _transactions.add({
        'id': i + 1,
        'userId': 1,
        'type': isIncome ? 'income' : 'expense',
        'amount': amount.toDouble(),
        'categoryId': cat['id'] as int,
        'category': cat,
        'description': isIncome ? '収入' : '支出',
        'date': DateFormat('yyyy-MM-dd').format(day),
      });
    }
  }

  dynamic handleGet(String path, {Map<String, String>? query}) {
    if (path.startsWith('/categories')) {
      final type = query?['type'];
      final list = type == null ? _categories : _categories.where((c) => c['type'] == type).toList();
      return list;
    }
    if (path.startsWith('/transactions')) {
      var list = _transactions.toList();
      final startDate = query?['startDate'];
      final endDate = query?['endDate'];
      if (startDate != null) {
        list = list.where((t) => (t['date'] as String).compareTo(startDate) >= 0).toList();
      }
      if (endDate != null) {
        list = list.where((t) => (t['date'] as String).compareTo(endDate) <= 0).toList();
      }
      return list..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    }
    if (path.startsWith('/stats')) {
      double income = 0, expense = 0;
      for (final t in _transactions) {
        if (t['type'] == 'income') income += (t['amount'] as num).toDouble();
        if (t['type'] == 'expense') expense += (t['amount'] as num).toDouble();
      }
      final now = DateTime.now();
      final ym = DateFormat('yyyy-MM').format(now);
      double mIncome = 0, mExpense = 0;
      for (final t in _transactions.where((t) => (t['date'] as String).startsWith(ym))) {
        if (t['type'] == 'income') mIncome += (t['amount'] as num).toDouble();
        if (t['type'] == 'expense') mExpense += (t['amount'] as num).toDouble();
      }
      return {
        'totalIncome': income,
        'totalExpense': expense,
        'currentBalance': income - expense,
        'thisMonthIncome': mIncome,
        'thisMonthExpense': mExpense,
        'transactionCount': _transactions.length,
      };
    }
    // default
    return null;
  }

  dynamic handlePost(String path, Map<String, dynamic> body) {
    if (path.startsWith('/transactions')) {
      final id = _transactions.length + 1;
      final matched = _categories.firstWhere(
        (c) => c['id'] == (body['categoryId'] as num).toInt(),
        orElse: () => <String, dynamic>{},
      );
      final map = {
        'id': id,
        'userId': 1,
        'type': body['type'] ?? 'expense',
        'amount': (body['amount'] as num).toDouble(),
        'categoryId': (body['categoryId'] as num).toInt(),
        'category': matched.isEmpty ? null : matched,
        'description': (body['description'] ?? '') as String,
        'date': (body['date'] as String?) ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };
      _transactions.add(map);
      return map;
    }
    if (path.startsWith('/categories')) {
      final id = _categories.length + 1;
      final map = {
        'id': id,
        'userId': 1,
        'name': body['name'] ?? '新カテゴリ',
        'type': body['type'] ?? 'expense',
        'color': body['color'] ?? '#999999',
        'icon': body['icon'] ?? '',
        'description': body['description'] ?? '',
      };
      _categories.add(map);
      return map;
    }
    return null;
  }

  dynamic handlePut(String path, Map<String, dynamic> body) {
    if (path.startsWith('/transactions/')) {
      final id = int.parse(path.split('/').last);
      final idx = _transactions.indexWhere((t) => t['id'] == id);
      if (idx == -1) return null;
      _transactions[idx].addAll(body);
      return _transactions[idx];
    }
    if (path.startsWith('/categories/')) {
      final id = int.parse(path.split('/').last);
      final idx = _categories.indexWhere((t) => t['id'] == id);
      if (idx == -1) return null;
      _categories[idx].addAll(body);
      return _categories[idx];
    }
    return null;
  }

  void handleDelete(String path) {
    if (path.startsWith('/transactions/')) {
      final id = int.parse(path.split('/').last);
      _transactions.removeWhere((t) => t['id'] == id);
    }
    if (path.startsWith('/categories/')) {
      final id = int.parse(path.split('/').last);
      _categories.removeWhere((t) => t['id'] == id);
    }
  }
}
