import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/features/stats/dashboard_screen.dart';
import 'package:money_tracker_mobile/features/calendar/calendar_screen.dart';
import 'package:money_tracker_mobile/features/reports/reports_screen.dart';
import 'package:money_tracker_mobile/features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _pages = const [
    DashboardScreen(),
    CalendarScreen(),
    ReportsScreen(),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '分析'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'カレンダー'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'レポート'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
