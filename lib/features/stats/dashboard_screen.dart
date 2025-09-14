import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/stats/stats_repository.dart';
import 'package:money_tracker_mobile/models/stats.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ダッシュボード', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric('今月の収入', s.thisMonthIncome),
                  _metric('今月の支出', s.thisMonthExpense),
                  _metric('総収入', s.totalIncome),
                  _metric('総支出', s.totalExpense),
                  _metric('現在の残高', s.currentBalance),
                  _metric('取引件数', s.transactionCount.toDouble()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String title, double value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

