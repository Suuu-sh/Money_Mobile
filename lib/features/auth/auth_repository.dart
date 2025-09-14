import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/core/token_store.dart';
import 'package:money_tracker_mobile/models/user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<(String token, User user)> login({required String email, required String password}) async {
    final res = await _api.postJson('/login', {
      'email': email,
      'password': password,
    });
    final map = (res as Map<String, dynamic>);
    final token = map['token'] as String;
    final user = User.fromJson(map['user'] as Map<String, dynamic>);
    await TokenStore.instance.setToken(token);
    return (token, user);
  }

  Future<(String token, User user)> register({required String email, required String password, required String name}) async {
    final res = await _api.postJson('/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    final map = (res as Map<String, dynamic>);
    final token = map['token'] as String;
    final user = User.fromJson(map['user'] as Map<String, dynamic>);
    await TokenStore.instance.setToken(token);
    return (token, user);
  }

  Future<User> me() async {
    final res = await _api.getJson('/me');
    return User.fromJson(res as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _api.postJson('/logout', <String, dynamic>{});
    await TokenStore.instance.setToken(null);
  }
}
