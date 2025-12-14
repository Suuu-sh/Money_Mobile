import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/core/category_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authRepo = AuthRepository(ApiClient());
  final _categoriesRepo = CategoriesRepository(ApiClient());
  bool _categoriesLoading = true;
  List<Category> _categories = [];
  String? _categoriesError;
  late final VoidCallback _dataListener;
  bool _expenseExpanded = false;
  bool _incomeExpanded = false;

  @override
  void initState() {
    super.initState();
    _dataListener = () {
      _loadCategories();
    };
    AppState.instance.dataVersion.addListener(_dataListener);
    _loadCategories();
  }

  @override
  void dispose() {
    AppState.instance.dataVersion.removeListener(_dataListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppState.instance.auth.value;
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
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                children: [
                  Icon(Icons.settings_rounded, 
                    size: 28, 
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Theme section
              _sectionCard(
                title: 'テーマ',
                icon: Icons.palette_rounded,
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppState.instance.themeMode,
                  builder: (context, mode, _) {
                    return Column(
                      children: [
                        _radioTile(
                          title: 'ライト（白ベース）',
                          icon: Icons.light_mode_rounded,
                          value: ThemeMode.light,
                          groupValue: mode,
                          onChanged: _setThemeMode,
                        ),
                        const SizedBox(height: 8),
                        _radioTile(
                          title: 'ダーク（黒ベース）',
                          icon: Icons.dark_mode_rounded,
                          value: ThemeMode.dark,
                          groupValue: mode,
                          onChanged: _setThemeMode,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              // App settings
              _sectionCard(
                title: 'アプリ設定',
                icon: Icons.tune_rounded,
                child: FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snap) {
                    final prefs = snap.data;
                    final startMonday = prefs?.getBool('startMonday') ?? true;
                    final currency = prefs?.getString('currency') ?? 'JPY';
                    return Column(
                      children: [
                        _settingRow(
                          icon: Icons.calendar_view_week_rounded,
                          label: '週の開始曜日',
                          child: Row(
                            children: [
                              _miniChip('月', startMonday, () async {
                                final p = await SharedPreferences.getInstance();
                                await p.setBool('startMonday', true);
                                if (mounted) setState(() {});
                              }),
                              const SizedBox(width: 8),
                              _miniChip('日', !startMonday, () async {
                                final p = await SharedPreferences.getInstance();
                                await p.setBool('startMonday', false);
                                if (mounted) setState(() {});
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingRow(
                          icon: Icons.attach_money_rounded,
                          label: '通貨',
                          child: DropdownButton<String>(
                            value: currency,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                            ],
                            onChanged: (v) async {
                              final p = await SharedPreferences.getInstance();
                              await p.setString('currency', v ?? 'JPY');
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'カテゴリ一覧',
                icon: Icons.category_rounded,
                child: _buildCategoryListSection(),
              ),

              const SizedBox(height: 24),
              if (session != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF9C27B0).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_rounded, 
                        color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ログイン中: ${session.user.email}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await _authRepo.logout();
                  AppState.instance.auth.value = null;
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('ログアウト', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF9C27B0).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _radioTile({
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required Function(ThemeMode) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = value == groupValue;
    final color = isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0);
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? (isDark ? color.withOpacity(0.15) : color.withOpacity(0.1)) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? color : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? color : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingRow({required IconData icon, required String label, required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _miniChip(String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (isDark ? color.withOpacity(0.2) : color.withOpacity(0.15)) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
            color: selected ? color : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    AppState.instance.themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString('themeMode', 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString('themeMode', 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString('themeMode', 'system');
        break;
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final cats = await _categoriesRepo.list();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoriesError = 'カテゴリの取得に失敗しました';
        _categoriesLoading = false;
      });
    }
  }

  Widget _buildCategoryListSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_categoriesLoading) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()));
    }
    if (_categoriesError != null) {
      return Text(
        _categoriesError!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (_categories.isEmpty) {
      return Text(
        'まだカテゴリが登録されていません',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final expense = _categories.where((c) => c.type == 'expense').toList();
    final income = _categories.where((c) => c.type == 'income').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryGroup(
          title: '支出カテゴリ (${expense.length})',
          categories: expense,
          expanded: _expenseExpanded,
          onToggle: () => setState(() => _expenseExpanded = !_expenseExpanded),
        ),
        const SizedBox(height: 12),
        _categoryGroup(
          title: '収入カテゴリ (${income.length})',
          categories: income,
          expanded: _incomeExpanded,
          onToggle: () => setState(() => _incomeExpanded = !_incomeExpanded),
        ),
      ],
    );
  }

  Widget _categoryGroup({
    required String title,
    required List<Category> categories,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final arrowIcon = expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF9C27B0).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.category_rounded, size: 18, color: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(arrowIcon, color: isDark ? Colors.white70 : Colors.black54),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: categories.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'カテゴリがありません',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    )
                  : Column(children: categories.map(_categoryTile).toList()),
            ),
        ],
      ),
    );
  }

  Widget _categoryTile(Category category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _categoryColor(category, fallback: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0));
    final iconData = category.icon.isNotEmpty
        ? CategoryIcons.getIcon(category.icon)
        : CategoryIcons.guessIcon(category.name, category.type);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (category.description.isNotEmpty)
                  Text(
                    category.description,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            category.type == 'income' ? '収入' : '支出',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(Category category, {Color fallback = const Color(0xFF9C27B0)}) {
    final hex = category.color.replaceAll('#', '');
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return fallback;
  }
}
