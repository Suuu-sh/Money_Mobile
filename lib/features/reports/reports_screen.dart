import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/models/stats.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = StatsRepository(ApiClient());
  Future<Stats>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch();
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
        return SafeArea(
          top: true,
          bottom: false,
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const SizedBox(height: 4),
              _statTile('今月の収入', s.thisMonthIncome, leading: Icons.trending_up, color: Colors.green),
              _statTile('今月の支出', s.thisMonthExpense, leading: Icons.trending_down, color: Colors.red),
              const Divider(height: 24),
              _statTile('総収入', s.totalIncome, leading: Icons.attach_money),
              _statTile('総支出', s.totalExpense, leading: Icons.money_off),
              _statTile('現在の残高', s.currentBalance, leading: Icons.account_balance_wallet),
              _statTile('取引件数', s.transactionCount.toDouble(), leading: Icons.list_alt),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _statTile(String title, double value, {IconData? leading, Color? color}) {
    return Card(
      child: ListTile(
        leading: Icon(leading ?? Icons.bar_chart, color: color),
        title: Text(title),
        trailing: Text(value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
