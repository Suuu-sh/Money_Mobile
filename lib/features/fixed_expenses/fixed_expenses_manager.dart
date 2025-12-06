import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_repository.dart';
import 'package:money_tracker_mobile/models/fixed_expense.dart';

class FixedExpensesManagerSheet extends StatefulWidget {
  const FixedExpensesManagerSheet({super.key});

  @override
  State<FixedExpensesManagerSheet> createState() => _FixedExpensesManagerSheetState();
}

class _FixedExpensesManagerSheetState extends State<FixedExpensesManagerSheet> {
  late final FixedExpensesRepository _repo;
  late Future<List<FixedExpense>> _future;

  @override
  void initState() {
    super.initState();
    _repo = FixedExpensesRepository(ApiClient());
    _future = _repo.list();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.list();
    });
  }

  Future<void> _openForm([FixedExpense? expense]) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FixedExpenseFormSheet(expense: expense, repo: _repo),
    );
    if (updated == true && mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const Text('固定費を管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<FixedExpense>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('読み込みに失敗しました: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('登録された固定費はありません'));
                  }
                  return ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final color = item.type == 'income' ? Colors.green : Colors.red;
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.type == 'income' ? '収入' : '支出'),
                        trailing: Text('${item.amount.toStringAsFixed(0)}円', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        onTap: () => _openForm(item),
                        leading: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('削除しますか？'),
                                content: Text('${item.name} を削除します'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _repo.delete(item.id);
                              if (mounted) _refresh();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('固定費を追加'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class FixedExpenseFormSheet extends StatefulWidget {
  const FixedExpenseFormSheet({super.key, this.expense, required this.repo});

  final FixedExpense? expense;
  final FixedExpensesRepository repo;

  @override
  State<FixedExpenseFormSheet> createState() => _FixedExpenseFormSheetState();
}

class _FixedExpenseFormSheetState extends State<FixedExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String _type = 'expense';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _nameController = TextEditingController(text: expense?.name ?? '');
    _amountController = TextEditingController(
      text: expense != null ? expense.amount.toStringAsFixed(0) : '',
    );
    _type = expense?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい金額を入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.expense == null) {
        await widget.repo.create(name: name, amount: amount, type: _type);
      } else {
        await widget.repo.update(
          widget.expense!.id,
          name: name,
          amount: amount,
          type: _type,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.expense == null ? '固定費を追加' : '固定費を編集', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '名称を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: '金額'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return '正しい金額を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: _type == 'expense',
                    onSelected: (_) => setState(() => _type = 'expense'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('収入'),
                    selected: _type == 'income',
                    onSelected: (_) => setState(() => _type = 'income'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
