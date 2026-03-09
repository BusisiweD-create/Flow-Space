// ignore_for_file: prefer_single_quotes

class Environment {
  // App Configuration
  static const String appName = 'Khonology';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A social learning platform built with Flutter';

  // API Configuration - Use const for production URL from build
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://localhost:3001/api/v1",
  );

  // Production fallback detection
  static String get apiBaseUrl {
    // First try build-time variable
    if (_apiBaseUrl != "http://localhost:3001/api/v1") {
      return _apiBaseUrl;
    }

    // Fallback to production URL if deployed on Render
    if (isRenderDeployed) {
      return "https://flow-space.onrender.com/api/v1";
    }

    // Default to localhost for development
    return _apiBaseUrl;
  }

  static const int apiTimeout = 30000;

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Development Settings
  static const bool debugMode =
      bool.fromEnvironment('DEBUG_MODE', defaultValue: true);
  static const String logLevel = 'debug';

  // Environment-specific configurations
  static bool get isProduction => !debugMode;
  static bool get isDevelopment => debugMode;

  // Check if running on Render.com or other production environments
  static bool get isRenderDeployed {
    // Check if we're in a browser environment and not localhost
    try {
      final uri = Uri.base;
      return uri.host.contains('onrender.com') ||
          uri.host.contains('flownet.works') ||
          (!uri.host.contains('localhost') && !uri.host.contains('127.0.0.1'));
    } catch (e) {
      return false;
    }
  }
}
