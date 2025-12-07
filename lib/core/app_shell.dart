import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/analysis/analysis_screen.dart';
import 'package:money_tracker_mobile/features/calendar/calendar_screen.dart';
import 'package:money_tracker_mobile/features/reports/reports_screen.dart';
import 'package:money_tracker_mobile/features/settings/settings_screen.dart';
import 'package:money_tracker_mobile/features/input/input_screen.dart';
import 'package:money_tracker_mobile/features/common/quick_actions.dart';
import 'package:money_tracker_mobile/features/fixed_expenses/fixed_expenses_manager.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _pages = const [
    CalendarScreen(),
    ReportsScreen(),
    AnalysisScreen(),
    // Settings without const due to field
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          ..._pages,
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1625), const Color(0xFF0F0B1A)]
                : [Colors.white, const Color(0xFFFFF5F7)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 70, maxHeight: 70),
            // padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _TabItem(
                    icon: Icons.calendar_today_rounded,
                    activeIcon: Icons.calendar_today_rounded,
                    label: 'カレンダー',
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'レポート',
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),
                Expanded(
                  child: _PlusTab(onTap: _openQuickInput),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.insights_rounded,
                    activeIcon: Icons.insights_rounded,
                    label: '分析',
                    selected: _index == 2,
                    onTap: () => setState(() => _index = 2),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.settings_rounded,
                    activeIcon: Icons.settings_rounded,
                    label: '設定',
                    selected: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuickInput() {
    _showQuickInputFlow();
  }

  Future<void> _showQuickInputFlow() async {
    final action = await showModalBottomSheet<QuickActionAction>(
      context: context,
      builder: (ctx) => const QuickActionSheet(),
    );
    if (!mounted || action == null) return;
    await _handleQuickAction(action);
  }

  Future<void> _handleQuickAction(QuickActionAction action) async {
    bool? result;
    switch (action) {
      case QuickActionAction.transaction:
        final initialDate = AppState.instance.quickEntryDate;
        result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => InputScreen(initialDate: initialDate),
        );
        break;
      case QuickActionAction.fixedExpense:
        result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const FixedExpenseFormSheet(),
        );
        break;
      case QuickActionAction.category:
        result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CategoryCreateSheet(),
        );
        break;
      case QuickActionAction.budget:
        result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const BudgetCreateSheet(),
        );
        break;
    }

    if (!mounted) return;
    if (result != true) {
      await _showQuickInputFlow();
    }
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = selected 
        ? (isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0))
        : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5));
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: selected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFFE1BEE7).withOpacity(0.2), const Color(0xFFE1BEE7).withOpacity(0.1)]
                            : [const Color(0xFF9C27B0).withOpacity(0.15), const Color(0xFF9C27B0).withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(selected ? activeIcon : icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusTab extends StatelessWidget {
  const _PlusTab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -16), // make it "pop" over the tab bar
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)]
                    : [const Color(0xFFBA68C8), const Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFFE1BEE7) : const Color(0xFF9C27B0)).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
