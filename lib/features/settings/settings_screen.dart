import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final _authRepo = AuthRepository(ApiClient());

  @override
  Widget build(BuildContext context) {
    final session = AppState.instance.auth.value;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Theme section
          const Text('テーマ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppState.instance.themeMode,
            builder: (context, mode, _) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    onChanged: (v) => _setThemeMode(v ?? ThemeMode.light),
                    title: const Text('ライト（白ベース）'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    onChanged: (v) => _setThemeMode(v ?? ThemeMode.dark),
                    title: const Text('ダーク（黒ベース）'),
                  ),
                ],
              );
            },
          ),

          const Spacer(),
          if (session != null) Text('ログイン中: ${session.user.email}'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await _authRepo.logout();
              AppState.instance.auth.value = null;
            },
            icon: const Icon(Icons.logout),
            label: const Text('ログアウト'),
          ),
        ],
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
}
