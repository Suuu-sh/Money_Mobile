// Only compiled on web via conditional import.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? get token => html.window.localStorage['token'];

Future<void> setToken(String? value) async {
  if (value == null) {
    html.window.localStorage.remove('token');
  } else {
    html.window.localStorage['token'] = value;
  }
}

