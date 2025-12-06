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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final Widget messageWidget = _message == null
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.contains('失敗') ? Colors.red.shade50 : Colors.green.shade50,
                  border: Border.all(color: _message!.contains('失敗') ? Colors.red.shade200 : Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.contains('失敗') ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 4),
          messageWidget,

          // Type toggle
          Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('収入'),
                selected: _type == 'income',
                onSelected: (_) => setState(() { _type = 'income'; _categoryId = null; }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('支出'),
                selected: _type == 'expense',
                onSelected: (_) => setState(() { _type = 'expense'; _categoryId = null; }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount & Date
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金額*'),
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
                    decoration: const InputDecoration(labelText: '日付*'),
                    child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
            decoration: const InputDecoration(labelText: 'カテゴリ*'),
            validator: (v) => v == null ? 'カテゴリを選択してください' : null,
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: '説明'),
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? '追加中...' : '取引を追加'),
            ),
          ),
        ],
      ),
    );
  }
}
