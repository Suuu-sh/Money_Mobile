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

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _type;
  int? _categoryId;
  List<Category> _allCategories = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: tx.amount.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: tx.description);
    _selectedDate = tx.date;
    _type = tx.type;
    _categoryId = tx.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _catRepo.list();
      if (!mounted) return;
      setState(() {
        _allCategories = list;
        final exists = _categoryId != null &&
            list.any((c) => c.id == _categoryId && c.type == _type);
        if (!exists) {
          _categoryId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリの取得に失敗しました')),
      );
    }
  }

  void _onTypeChanged(String nextType) {
    if (_type == nextType) return;
    setState(() {
      _type = nextType;
      final exists = _categoryId != null &&
          _allCategories.any((c) => c.id == _categoryId && c.type == _type);
      if (!exists) {
        _categoryId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _allCategories.where((c) => c.type == _type).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
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
                ChoiceChip(
                  label: const Text('収入'),
                  selected: _type == 'income',
                  onSelected: (_) => _onTypeChanged('income'),
                ),
                ChoiceChip(
                  label: const Text('支出'),
                  selected: _type == 'expense',
                  onSelected: (_) => _onTypeChanged('expense'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
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
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '日付'),
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _categoryId,
              items: filteredCategories
                  .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'カテゴリ'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '説明（任意）'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final categoryId = _categoryId;
    if (amount == null || amount <= 0 || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額とカテゴリを入力してください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _txRepo.update(
        widget.transaction.id,
        type: _type,
        amount: amount,
        categoryId: categoryId,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
      );
      if (!mounted) return;
      AppState.instance.bumpDataVersion();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
