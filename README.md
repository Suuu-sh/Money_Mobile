# MoneyTracker Mobile (Flutter)

This is the Flutter mobile client for MoneyTracker.

## Prerequisites
- Flutter SDK (stable channel)
- Android SDK / Xcode (for Android/iOS builds)
- Dart enabled in your editor (VS Code/Android Studio recommended)

## Getting Started

1. Switch to the repository root and open the `Mobile` directory:
   
   ```bash
   cd Mobile
   ```

2. Fetch packages:
   
   ```bash
   flutter pub get
   ```

3. Run the app (configure API base URL via --dart-define):
  
  ```bash
  # Example: local backend
  flutter run --dart-define=API_BASE_URL=http://localhost:8000/api

 # Example: production backend
  flutter run --dart-define=API_BASE_URL=https://your-api-domain.com/api
  ```

4. Run on Web (Chrome) to avoid Xcode/Pods during setup:

   ```bash
   # Use port 3000 to match backend CORS allowlist
   flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api
   ```

The app now includes:
- Auth (login/register) screens with token handling
- Dashboard with `/stats`
- Transactions list with basic create
- Categories list with filtering
- Settings with logout

Networking is via `lib/core/api_client.dart` and base URL is read from `--dart-define=API_BASE_URL` (defaults to `http://localhost:8000/api`).

## Next Steps
- Add feature modules (auth, dashboard, transactions, budgets) under `lib/features`.
- Persist token across platforms. Currently, Web persists to localStorage; other platforms keep it in-memory.
- Add platform integration (icons/splash) via `flutter_native_splash` and `flutter_launcher_icons`.

## Notes on platform folders
This directory does not include platform folders by default (android/ios/macos/windows).
If you need them, run from inside `Mobile/`:

```bash
flutter create .
```

This will generate the necessary platform projects without overwriting existing Dart code.

## Folder Structure (suggested)
```
Mobile/
 ├─ lib/
 │   ├─ core/            # shared utilities, theming, routing
 │   ├─ features/        # feature modules (auth, dashboard, etc.)
 │   └─ main.dart        # app entry
 ├─ pubspec.yaml
 ├─ analysis_options.yaml
 └─ .gitignore
```
