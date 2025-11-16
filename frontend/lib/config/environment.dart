import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  static String get apiBaseUrl => kIsWeb
      ? 'http://localhost:8000/api/v1'
      : 'http://localhost:8000/api/v1';
  static const int apiTimeout = 30000;
}