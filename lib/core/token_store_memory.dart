String? _memoryToken;

String? get token => _memoryToken;

Future<void> setToken(String? value) async {
  _memoryToken = value;
}

