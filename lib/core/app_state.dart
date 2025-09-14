import 'package:flutter/foundation.dart';
import 'package:money_tracker_mobile/models/user.dart';

class AuthSession {
  final String token;
  final User user;
  const AuthSession({required this.token, required this.user});
}

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<AuthSession?> auth = ValueNotifier<AuthSession?>(null);
}

