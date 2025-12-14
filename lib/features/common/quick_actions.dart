import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/features/budgets/category_budgets_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/core/category_icons.dart';

enum QuickActionAction { transaction, fixedExpense, category, budget }

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_rounded,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'クイックアクション',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _actionTile(
                context: context,
                icon: Icons.add_circle_rounded,
                title: '取引を追加',
                color: const Color(0xFF66BB6A),
                onTap: () => Navigator.of(context).pop(QuickActionAction.transaction),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context: context,
                icon: Icons.repeat_rounded,
                title: '固定費を追加',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.of(context).pop(QuickActionAction.fixedExpense),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context: context,
                icon: Icons.category_rounded,
                title: 'カテゴリを作成',
                color: const Color(0xFF42A5F5),
                onTap: () => Navigator.of(context).pop(QuickActionAction.category),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                title: '予算を設定',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.of(context).pop(QuickActionAction.budget),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
            ),
          ],
        ),
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
  final _color = TextEditingController(text: '#FF6B6B');
  final _icon = TextEditingController(text: 'food');
  bool _saving = false;
  static const _colorPresets = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#F7B801', '#D4A5A5', '#7D83FF', '#26A69A', '#F48FB1'
  ];
  static const _iconPresets = ['food', 'shopping', 'transport', 'home', 'utilities', 'entertainment', 'education', 'salary'];

  @override
  void initState() {
    super.initState();
    _name.addListener(_updateIconAndColor);
  }

  @override
  void dispose() {
    _name.removeListener(_updateIconAndColor);
    super.dispose();
  }

  void _updateIconAndColor() {
    // 名前に基づいてアイコンと色を自動設定
    final name = _name.text;
    if (name.isEmpty) return;

    final defaults = CategoryIcons.getDefaultCategories();
    final match = defaults.firstWhere(
      (d) => d['name'] == name && d['type'] == _type,
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      _color.text = match['color']!;
      _icon.text = match['icon']!;
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'カテゴリを作成',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: '名前',
                    prefixIcon: Icon(Icons.label_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    _buildTypeChip('支出', Icons.arrow_circle_down_rounded, _type == 'expense', () {
                      setState(() => _type = 'expense');
                      _updateIconAndColor();
                    }),
                    _buildTypeChip('収入', Icons.arrow_circle_up_rounded, _type == 'income', () {
                      setState(() => _type = 'income');
                      _updateIconAndColor();
                    }),
                  ],
                ),
                const SizedBox(height: 18),
                Text('カラー', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorPresets
                      .map(
                        (hex) => ChoiceChip(
                          label: const SizedBox.shrink(),
                          selected: _color.text.toLowerCase() == hex.toLowerCase(),
                          onSelected: (_) => setState(() => _color.text = hex),
                          backgroundColor: _hexToColor(hex).withOpacity(0.4),
                          selectedColor: _hexToColor(hex),
                          shape: const CircleBorder(),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text('アイコン', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _iconPresets
                      .map(
                        (icon) => ChoiceChip(
                          label: Icon(CategoryIcons.getIcon(icon), color: _icon.text == icon ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
                          selected: _icon.text == icon,
                          selectedColor: _hexToColor(_color.text),
                          onSelected: (_) => setState(() => _icon.text = icon),
                          backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('キャンセル', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check_rounded),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        label: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('作成', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
      if (mounted) Navigator.pop(context, true);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_loading) {
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
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
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
                    Icons.account_balance_wallet_rounded,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'カテゴリ別予算を設定',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                items: _categories
                    .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  prefixIcon: Icon(Icons.category_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
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
                        decoration: InputDecoration(
                          labelText: '対象月',
                          prefixIcon: Icon(Icons.calendar_month_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(DateFormat('yyyy/MM').format(_month)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '金額',
                        prefixIcon: Icon(Icons.payments_rounded, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_rounded, color: Color(0xFFEF5350), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
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
