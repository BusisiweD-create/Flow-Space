// ignore_for_file: prefer_single_quotes

class Environment {
  // App Configuration
  static const String appName = 'Khonology';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A social learning platform built with Flutter';

  // API Configuration
  static const String apiBaseUrl = "http://localhost:8000/api/v1";
  static const int apiTimeout = 30000;

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Development Settings
  static const bool debugMode = true;
  static const String logLevel = 'debug';

  // Environment-specific configurations
  static bool get isProduction => !debugMode;
  static bool get isDevelopment => debugMode;
}
