/// Global configuration for the mobile app.
///
/// The API base URL can be provided at runtime using:
///   flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
/// Falls back to localhost for development if not provided.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
}

