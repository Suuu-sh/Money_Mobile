import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/features/transactions/transactions_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/core/app_state.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _txRepo = TransactionsRepository(ApiClient());
  final _catRepo = CategoriesRepository(ApiClient());

  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  final _amountController = TextEditingController();
  int? _categoryId;
  DateTime _date = DateTime.now();
  final _descController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  List<Category> _categories = [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.initialDate != null) {
      _date = widget.initialDate!;
      AppState.instance.updateQuickEntryDate(_date);
    } else {
      AppState.instance.updateQuickEntryDate(_date);
    }
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final cats = await _catRepo.list();
      setState(() => _categories = cats);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Category> get _filteredCategories => _categories.where((c) => c.type == _type).toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _message = 'カテゴリを選択してください');
      return;
    }
    setState(() => _submitting = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      await _txRepo.create(
        type: _type,
        amount: amount,
        categoryId: _categoryId!,
        description: _descController.text,
        date: _date,
      );
      if (mounted) {
        _message = '取引を追加しました';
        _amountController.clear();
        _descController.clear();
      }
      AppState.instance.updateQuickEntryDate(_date);
      // クイック入力用途では追加後に閉じる + 通知
      AppState.instance.bumpDataVersion();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _message = '取引の作成に失敗しました');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _cancel() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Widget messageWidget = _message == null
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _message!.contains('失敗')
                        ? [const Color(0xFFEF5350).withOpacity(0.2), const Color(0xFFEF5350).withOpacity(0.1)]
                        : [const Color(0xFF66BB6A).withOpacity(0.2), const Color(0xFF66BB6A).withOpacity(0.1)],
                  ),
                  border: Border.all(
                    color: _message!.contains('失敗') ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _message!.contains('失敗') ? Icons.error_rounded : Icons.check_circle_rounded,
                      color: _message!.contains('失敗') ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.contains('失敗') ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Icon(
                Icons.add_circle_rounded,
                color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                '取引を追加',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          messageWidget,

          // Type toggle
          Wrap(
            spacing: 10,
            children: <Widget>[
              _buildTypeChip('収入', Icons.arrow_circle_up_rounded, _type == 'income', () {
                setState(() { _type = 'income'; _categoryId = null; });
              }),
              _buildTypeChip('支出', Icons.arrow_circle_down_rounded, _type == 'expense', () {
                setState(() { _type = 'expense'; _categoryId = null; });
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Amount & Date
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '金額*',
                    prefixIcon: Icon(Icons.payments_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return '正しい金額を入力してください';
                    return null;
                  },
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
                    if (picked != null) {
                      setState(() => _date = picked);
                      AppState.instance.updateQuickEntryDate(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '日付*',
                      prefixIcon: Icon(Icons.calendar_today_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<int>(
            value: _categoryId,
            items: _filteredCategories
                .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
            decoration: InputDecoration(
              labelText: 'カテゴリ*',
              prefixIcon: Icon(Icons.category_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (v) => v == null ? 'カテゴリを選択してください' : null,
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: '説明（任意）',
              prefixIcon: Icon(Icons.notes_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('キャンセル', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded, size: 24),
                  label: Text(
                    _submitting ? '追加中...' : '取引を追加',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
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
}
