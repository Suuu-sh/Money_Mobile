import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key, required this.onCreateTransaction});

  final VoidCallback onCreateTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
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
            const Text('月次予算を設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget-${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    await prefs.setDouble(key, amount);
    if (mounted) Navigator.pop(context);
    setState(() => _saving = false);
  }
}

