import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/app_shell.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
// Login screen is disabled during testing
import 'package:money_tracker_mobile/core/token_store.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';
import 'package:money_tracker_mobile/models/user.dart';

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
    // Always mark as logged in for testing
    const fakeToken = 'dev-test-token';
    await TokenStore.instance.setToken(fakeToken);
    AppState.instance.auth.value = AuthSession(
      token: fakeToken,
      user: User(id: 0, email: 'test@example.com', name: 'Tester'),
    );
    if (mounted) setState(() => _bootstrapped = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'MoneyTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
