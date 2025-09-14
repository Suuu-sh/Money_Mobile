import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_shell.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/auth/login_screen.dart';
import 'package:money_tracker_mobile/core/token_store.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';

void main() {
  runApp(const MoneyTrackerApp());
}

class MoneyTrackerApp extends StatefulWidget {
  const MoneyTrackerApp({super.key});

  @override
  State<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends State<MoneyTrackerApp> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = TokenStore.instance.token;
    if (token != null && token.isNotEmpty) {
      try {
        final user = await AuthRepository(ApiClient()).me();
        AppState.instance.auth.value = AuthSession(token: token, user: user);
      } catch (_) {
        // ignore failures; stay logged out
      }
    }
    if (mounted) setState(() => _bootstrapped = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: AppState.instance.auth,
      builder: (context, session, _) {
        return MaterialApp(
          title: 'MoneyTracker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E)),
            useMaterial3: true,
          ),
          home: session == null ? const LoginScreen() : const AppShell(),
        );
      },
    );
  }
}
