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
