import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:money_tracker_mobile/core/app_shell.dart';
import 'package:money_tracker_mobile/core/app_state.dart';
import 'package:money_tracker_mobile/features/auth/login_screen.dart';
import 'package:money_tracker_mobile/core/token_store.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/auth/auth_repository.dart';
import 'package:money_tracker_mobile/models/user.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize intl date symbols for Japanese (used by DateFormat('E'), etc.)
  await initializeDateFormatting('ja');
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
    // Restore session if token exists
    final token = TokenStore.instance.token;
    if (token != null && token.isNotEmpty) {
      try {
        final user = await AuthRepository(ApiClient()).me();
        AppState.instance.auth.value = AuthSession(token: token, user: user);
      } catch (_) {
        // invalid token -> clear
        await TokenStore.instance.setToken(null);
        AppState.instance.auth.value = null;
      }
    }
    // Load theme mode from prefs
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    if (mode == 'dark') {
      AppState.instance.themeMode.value = ThemeMode.dark;
    } else if (mode == 'light') {
      AppState.instance.themeMode.value = ThemeMode.light;
    } else if (mode == 'system') {
      AppState.instance.themeMode.value = ThemeMode.system;
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<AuthSession?>(
          valueListenable: AppState.instance.auth,
          builder: (context, session, __) {
            return MaterialApp(
              title: 'MoneyTracker',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.light),
                scaffoldBackgroundColor: const Color(0xFFF8FAF7),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF22C55E),
                  brightness: Brightness.dark,
                ).copyWith(
                  surface: const Color(0xFF151718),
                  surfaceContainer: const Color(0xFF1B1E20),
                  background: const Color(0xFF121415),
                ),
                scaffoldBackgroundColor: const Color(0xFF121415),
                useMaterial3: true,
              ),
              themeMode: mode,
              locale: const Locale('ja'),
              supportedLocales: const [Locale('ja'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: session == null ? const LoginScreen() : const AppShell(),
            );
          },
        );
      },
    );
  }
}
