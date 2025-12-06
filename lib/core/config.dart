import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global configuration for the mobile app.
///
/// The API base URL can be provided at runtime using:
///   flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
/// Falls back to localhost for development if not provided.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  // Use mock data instead of real backend during testing.
  // Set with: --dart-define=USE_MOCK=false to disable.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );
}

/// Secrets (loaded from `.env.mobile`) for local/test automation.
class SecretConfig {
  static bool get autoLoginEnabled =>
      (dotenv.maybeGet('AUTO_LOGIN_ENABLED') ?? '').toLowerCase() == 'true';

  static String? get autoLoginEmail => dotenv.maybeGet('TEST_LOGIN_EMAIL');

  static String? get autoLoginPassword => dotenv.maybeGet('TEST_LOGIN_PASSWORD');
}
