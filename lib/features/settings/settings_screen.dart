import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';

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
          const SizedBox(height: 12),
          if (session != null) Text('ログイン中: ${session.user.email}'),
          const Spacer(),
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
}

