import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/models/user.dart';

class AuthSession {
  final String token;
  final User user;
  const AuthSession({required this.token, required this.user});
}

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<AuthSession?> auth = ValueNotifier<AuthSession?>(null);
  // Theme mode for the app. Default is light.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  // Data version: bump when transactions/categories/budgets change
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);
  // Last date used/selected when launching quick transaction input
  DateTime _quickEntryDate = DateTime.now();
  // Shared current month across calendar/report views
  final ValueNotifier<DateTime> currentMonth = ValueNotifier<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month),
  );

  void bumpDataVersion() {
    dataVersion.value = dataVersion.value + 1;
  }

  DateTime get quickEntryDate => _quickEntryDate;

  void updateQuickEntryDate(DateTime date) {
    // Normalize to midnight to avoid tz drift
    _quickEntryDate = DateTime(date.year, date.month, date.day);
  }

  void setCurrentMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    final existing = currentMonth.value;
    if (existing.year == normalized.year && existing.month == normalized.month) {
      return;
    }
    currentMonth.value = normalized;
  }
}
