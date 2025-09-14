import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _repo = TransactionsRepository(ApiClient());
  late Future<List<MoneyTransaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.list();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.list());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MoneyTransaction>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('読み込みエラー: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('取引がありません'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final t = items[i];
                final sign = t.type == 'income' ? '+' : '-';
                final color = t.type == 'income' ? Colors.green : Colors.red;
                return ListTile(
                  title: Text(t.category?.name ?? '(カテゴリ不明)'),
                  subtitle: Text(t.description.isEmpty ? t.date.toIso8601String().substring(0, 10) : t.description),
                  trailing: Text(
                    '$sign${t.amount.toStringAsFixed(0)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    String type = 'expense';
    int? categoryId;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('取引の追加'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('支出')),
                  DropdownMenuItem(value: 'income', child: Text('収入')),
                ],
                onChanged: (v) => type = v ?? 'expense',
                decoration: const InputDecoration(labelText: 'タイプ'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: '金額'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'メモ'),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'カテゴリID（暫定）'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              categoryId = int.tryParse(controller.text);
              final amount = double.tryParse(amountController.text) ?? 0;
              if (categoryId == null || amount <= 0) return;
              await _repo.create(
                type: type,
                amount: amount,
                categoryId: categoryId!,
                description: descriptionController.text,
                date: date,
              );
              if (mounted) Navigator.pop(context);
              _refresh();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}

