import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_manager.dart';
import 'package:money_tracker_mobile/features/budgets/category_budgets_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key, required this.onCreateTransaction});

  final VoidCallback onCreateTransaction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('取引を追加'),
            onTap: onCreateTransaction,
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('固定費を追加'),
            onTap: () async {
              Navigator.of(context).pop();
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FixedExpenseFormSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('カテゴリを作成'),
            onTap: () async {
              Navigator.of(context).pop();
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const CategoryCreateSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('予算を設定'),
            onTap: () async {
              Navigator.of(context).pop();
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const BudgetCreateSheet(),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class CategoryCreateSheet extends StatefulWidget {
  const CategoryCreateSheet({super.key});

  @override
  State<CategoryCreateSheet> createState() => _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends State<CategoryCreateSheet> {
  final _repo = CategoriesRepository(ApiClient());
  final _name = TextEditingController();
  String _type = 'expense';
  final _color = TextEditingController(text: '#22C55E');
  final _icon = TextEditingController(text: '');
  bool _saving = false;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('カテゴリを作成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名前'),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            TextField(
              controller: _color,
              decoration: const InputDecoration(labelText: '色（#RRGGBB）'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _icon,
              decoration: const InputDecoration(labelText: 'アイコン（任意）'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('キャンセル')),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('作成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.create(Category(
        id: 0,
        userId: 0,
        name: _name.text.trim(),
        type: _type,
        color: _color.text.trim(),
        icon: _icon.text.trim(),
        description: '',
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class BudgetCreateSheet extends StatefulWidget {
  const BudgetCreateSheet({super.key});

  @override
  State<BudgetCreateSheet> createState() => _BudgetCreateSheetState();
}

class _BudgetCreateSheetState extends State<BudgetCreateSheet> {
  final _amount = TextEditingController();
  final _catRepo = CategoriesRepository(ApiClient());
  final _budgetRepo = CategoryBudgetsRepository(ApiClient());
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _saving = false;
  bool _loading = true;
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _catRepo.list();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'カテゴリの取得に失敗しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
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
            const Text('カテゴリ別予算を設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              items: _categories
                  .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              decoration: const InputDecoration(labelText: 'カテゴリ'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _month,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: '月の任意の日を選択',
                      );
                      if (picked != null) setState(() => _month = DateTime(picked.year, picked.month));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '対象月'),
                      child: Text(DateFormat('yyyy/MM').format(_month)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '金額'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('キャンセル')),
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
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0 || _selectedCategoryId == null) {
      setState(() => _error = 'カテゴリと正しい金額を入力してください');
      return;
    }
    setState(() => _saving = true);
    try {
      await _budgetRepo.create(
        categoryId: _selectedCategoryId!,
        year: _month.year,
        month: _month.month,
        amount: amount,
      );
      AppState.instance.bumpDataVersion();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = '予算の保存に失敗しました');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
