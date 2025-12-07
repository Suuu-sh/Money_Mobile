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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1625), const Color(0xFF0F0B1A)]
              : [const Color(0xFFFFF5F7), const Color(0xFFF3E5F5)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '取引を編集',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  _buildTypeChip('収入', Icons.arrow_circle_up_rounded, _type == 'income', () => _onTypeChanged('income')),
                  _buildTypeChip('支出', Icons.arrow_circle_down_rounded, _type == 'expense', () => _onTypeChanged('expense')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '金額',
                        prefixIcon: Icon(Icons.payments_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
                        decoration: InputDecoration(
                          labelText: '日付',
                          prefixIcon: Icon(Icons.calendar_today_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  prefixIcon: Icon(Icons.category_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '説明（任意）',
                  prefixIcon: Icon(Icons.notes_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: const Color(0xFFEF5350),
                        side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
                      ),
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('削除', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('保存', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: isDark
                      ? [color.withOpacity(0.3), color.withOpacity(0.2)]
                      : [color.withOpacity(0.2), color.withOpacity(0.1)],
                )
              : null,
          color: selected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                color: selected ? color : (isDark ? Colors.white70 : Colors.black54),
              ),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: const Color(0xFFEF5350)),
            const SizedBox(width: 10),
            const Text('削除確認'),
          ],
        ),
        content: const Text('この取引を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _txRepo.delete(widget.transaction.id);
      if (!mounted) return;
      AppState.instance.bumpDataVersion();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
