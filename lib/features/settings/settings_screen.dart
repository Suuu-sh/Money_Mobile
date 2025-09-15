import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

          const SizedBox(height: 16),
          // App settings
          const Text('アプリ設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snap) {
              final prefs = snap.data;
              final startMonday = prefs?.getBool('startMonday') ?? true;
              final currency = prefs?.getString('currency') ?? 'JPY';
              return Column(
                children: [
                  // First day of week
                  Row(
                    children: [
                      const Text('週の開始曜日'),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('月'),
                        selected: startMonday,
                        onSelected: (_) async { final p = await SharedPreferences.getInstance(); await p.setBool('startMonday', true); if (mounted) setState(() {}); },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('日'),
                        selected: !startMonday,
                        onSelected: (_) async { final p = await SharedPreferences.getInstance(); await p.setBool('startMonday', false); if (mounted) setState(() {}); },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Currency
                  Row(
                    children: [
                      const Text('通貨'),
                      const Spacer(),
                      DropdownButton<String>(
                        value: currency,
                        items: const [
                          DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        ],
                        onChanged: (v) async { final p = await SharedPreferences.getInstance(); await p.setString('currency', v ?? 'JPY'); if (mounted) setState(() {}); },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          // Data management
          const Text('データ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final map = <String, dynamic>{};
                  for (final k in ['themeMode', 'startMonday', 'currency']) {
                    if (prefs.containsKey(k)) map[k] = prefs.get(k);
                  }
                  final jsonText = const JsonEncoder.withIndent('  ').convert(map);
                  if (context.mounted) {
                    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('設定をエクスポート'), content: SingleChildScrollView(child: SelectableText(jsonText)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))]));
                  }
                },
                child: const Text('設定をエクスポート'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('設定をインポート'),
                      content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: '{\n  "themeMode": "dark"\n}')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                        TextButton(onPressed: () async {
                          try {
                            final data = jsonDecode(controller.text) as Map<String, dynamic>;
                            final prefs = await SharedPreferences.getInstance();
                            if (data.containsKey('themeMode')) await prefs.setString('themeMode', data['themeMode'] as String);
                            if (data.containsKey('startMonday')) await prefs.setBool('startMonday', data['startMonday'] as bool);
                            if (data.containsKey('currency')) await prefs.setString('currency', data['currency'] as String);
                            if (context.mounted) Navigator.pop(context);
                          } catch (_) { if (context.mounted) Navigator.pop(context); }
                          if (mounted) setState(() {});
                        }, child: const Text('読み込み')),
                      ],
                    ),
                  );
                },
                child: const Text('設定をインポート'),
              ),
            ],
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
