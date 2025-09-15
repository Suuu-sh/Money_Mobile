import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/features/analysis/analysis_screen.dart';
import 'package:money_tracker_mobile/features/calendar/calendar_screen.dart';
import 'package:money_tracker_mobile/features/reports/reports_screen.dart';
import 'package:money_tracker_mobile/features/settings/settings_screen.dart';
import 'package:money_tracker_mobile/features/input/input_screen.dart';
import 'package:money_tracker_mobile/features/common/quick_actions.dart';

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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ..._pages,
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'カレンダー',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
              ),
              Expanded(
                child: _TabItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
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
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights,
                  label: '分析',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
              ),
              Expanded(
                child: _TabItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: '設定',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickInput() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => QuickActionSheet(
        onCreateTransaction: () async {
          Navigator.of(ctx).pop();
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (inner) => SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(inner).viewInsets.bottom),
                child: SizedBox(
                  height: MediaQuery.of(inner).size.height * 0.8,
                  child: const InputScreen(),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
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
    final bg = Theme.of(context).colorScheme.primaryContainer;
    final fg = Theme.of(context).colorScheme.onPrimaryContainer;
    return Center(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(Icons.add, color: fg),
        ),
      ),
    );
  }
}
