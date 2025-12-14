import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/features/common/quick_actions.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
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
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '固定費を管理',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 64,
                                color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '登録された固定費はありません',
                                style: TextStyle(
                                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final color = item.type == 'income' ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
                          return InkWell(
                            onTap: () => _openForm(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                                    ),
                                    child: Icon(
                                      item.type == 'income' ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.type == 'income' ? '収入' : '支出',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${item.amount.toStringAsFixed(0)}円',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openForm(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 24),
                    label: const Text('固定費を追加', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FixedExpenseFormSheet extends StatefulWidget {
  const FixedExpenseFormSheet({super.key, this.expense, this.repo});

  final FixedExpense? expense;
  final FixedExpensesRepository? repo;

  @override
  State<FixedExpenseFormSheet> createState() => _FixedExpenseFormSheetState();
}

class _FixedExpenseFormSheetState extends State<FixedExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  String _type = 'expense';
  bool _saving = false;
  final _catRepo = CategoriesRepository(ApiClient());
  bool _categoriesLoading = true;
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _nameController = TextEditingController(text: expense?.name ?? '');
    _amountController = TextEditingController(
      text: expense != null ? expense.amount.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: expense?.description ?? '');
    _type = expense?.type ?? 'expense';
    _selectedCategoryId = expense?.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoryError = null;
    });
    try {
      final cats = await _catRepo.list();
      if (!mounted) return;
      _categories = cats;
      _selectedCategoryId = _resolveCategoryForType(_type, fallbackId: _selectedCategoryId);
    } catch (e) {
      if (!mounted) return;
      _categoryError = 'カテゴリの取得に失敗しました';
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  int? _resolveCategoryForType(String type, {int? fallbackId}) {
    final filtered = _categories.where((c) => c.type == type).toList();
    if (filtered.isEmpty) return null;
    if (fallbackId != null && filtered.any((c) => c.id == fallbackId)) {
      return fallbackId;
    }
    return filtered.first.id;
  }

  List<Category> get _filteredCategories =>
      _categories.where((c) => c.type == _type).toList();

  Future<void> _openNewCategorySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const CategoryCreateSheet(),
    );
    _loadCategories();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい金額を入力してください')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      setState(() => _categoryError = 'カテゴリを選択してください');
      return;
    }
    setState(() => _categoryError = null);
    final categoryId = _selectedCategoryId!;
    setState(() => _saving = true);
    try {
      final repo = widget.repo ?? FixedExpensesRepository(ApiClient());
      if (widget.expense == null) {
        await repo.create(
          name: name,
          amount: amount,
          type: _type,
          categoryId: categoryId,
          description: description,
        );
      } else {
        await repo.update(
          widget.expense!.id,
          name: name,
          amount: amount,
          type: _type,
          categoryId: categoryId,
          description: description,
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

  Future<void> _delete() async {
    if (widget.expense == null) return;

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
        content: Text('${widget.expense!.name} を削除しますか？\nこの操作は取り消せません。'),
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
      final repo = widget.repo ?? FixedExpensesRepository(ApiClient());
      await repo.delete(widget.expense!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.expense == null ? Icons.add_circle_rounded : Icons.edit_rounded,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.expense == null ? '固定費を追加' : '固定費を編集',
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
                    _buildTypeChip('支出', Icons.arrow_circle_down_rounded, _type == 'expense', () {
                      setState(() {
                        _type = 'expense';
                        _selectedCategoryId = _resolveCategoryForType('expense');
                      });
                    }),
                    _buildTypeChip('収入', Icons.arrow_circle_up_rounded, _type == 'income', () {
                      setState(() {
                        _type = 'income';
                        _selectedCategoryId = _resolveCategoryForType('income');
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '名称',
                    hintText: '例: 家賃、給料',
                    prefixIcon: Icon(Icons.label_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '名称を入力してください' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: '金額',
                    prefixIcon: Icon(Icons.payments_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return '正しい金額を入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_categoriesLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_categoryError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _categoryError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_filteredCategories.isEmpty)
                    const Text(
                      'このタイプのカテゴリがありません。設定からカテゴリを作成してください。',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      items: _filteredCategories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      decoration: InputDecoration(
                        labelText: 'カテゴリ',
                        prefixIcon: Icon(Icons.category_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (v) => v == null ? 'カテゴリを選択してください' : null,
                    ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '説明（任意）',
                    hintText: '詳細情報を入力',
                    prefixIcon: Icon(Icons.notes_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (widget.expense != null) ...[
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
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
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
