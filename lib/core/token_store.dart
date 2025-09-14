import 'token_store_memory.dart'
    if (dart.library.html) 'token_store_web.dart' as impl;

/// Facade for token storage.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  String? get token => impl.token;
  Future<void> setToken(String? value) => impl.setToken(value);
}
