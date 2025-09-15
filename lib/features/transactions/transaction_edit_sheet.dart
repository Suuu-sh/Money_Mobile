import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/models/transaction.dart';

class TransactionEditSheet extends StatefulWidget {
  const TransactionEditSheet({super.key, required this.transaction});
  final MoneyTransaction transaction;

  @override
  State<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<TransactionEditSheet> {
  final _txRepo = TransactionsRepository(ApiClient());
  final _catRepo = CategoriesRepository(ApiClient());

  final _amount = TextEditingController();
  final _desc = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  late String _type;
  List<Category> _cats = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amount.text = t.amount.toStringAsFixed(0);
    _desc.text = t.description;
    _date = t.date;
    _categoryId = t.categoryId;
    _type = t.type;
    _loadCats();
  }

  Future<void> _loadCats() async {
    final list = await _catRepo.list();
    if (!mounted) return;
    setState(() => _cats = list);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('取引を編集', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('収入'), selected: _type == 'income', onSelected: (_) => setState(() => _type = 'income')),
                ChoiceChip(label: const Text('支出'), selected: _type == 'expense', onSelected: (_) => setState(() => _type = 'expense')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '金額'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '日付'),
                      child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _categoryId,
              items: _cats
                  .where((c) => c.type == _type)
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(labelText: 'カテゴリ'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: '説明（任意）'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('キャンセル')),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0 || _categoryId == null) return;
    setState(() => _saving = true);
    try {
      await _txRepo.update(
        widget.transaction.id,
        type: _type,
        amount: amt,
        categoryId: _categoryId,
        description: _desc.text.trim(),
        date: _date,
      );
      if (mounted) {
        AppState.instance.bumpDataVersion();
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
