import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/version_control.dart';

class VersionService {
  static Map<String, dynamic>? _cachedVersionInfo;

  static Future<Map<String, dynamic>> getVersionDetailsFromAsset() async {
    if (_cachedVersionInfo != null) {
      return _cachedVersionInfo!;
    }

    try {
      final rawJson = await rootBundle.loadString('assets/data/version.json');
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        _cachedVersionInfo = decoded;
        return decoded;
      }
    } catch (_) {
      // Fallback to generated version when asset is missing/unreadable.
    }

    _cachedVersionInfo = VersionControl.getVersionInfo();
    return _cachedVersionInfo!;
  }

  static Map<String, dynamic> getVersionDetails() {
    if (_cachedVersionInfo != null) {
      return _cachedVersionInfo!;
    }
    return VersionControl.getVersionInfo();
  }

  static String getLatestCommitTooltip(Map<String, dynamic> versionInfo) {
    final commits = versionInfo['commits'];
    if (commits is List && commits.isNotEmpty) {
      final latest = commits.first;
      if (latest is Map) {
        final author = latest['author']?.toString().trim();
        final message = latest['message']?.toString().trim();
        if ((author != null && author.isNotEmpty) &&
            (message != null && message.isNotEmpty)) {
          return 'Latest commit by @$author\n$message';
        }
      }
    }
    return 'No recent commits available';
  }
  
  static String getCurrentVersion() {
    if (_cachedVersionInfo != null && _cachedVersionInfo!['version'] != null) {
      return _cachedVersionInfo!['version'].toString();
    }
    return VersionControl.generateVersionNumber();
  }
  
  static String getEnvironment() {
    return VersionControl.environment;
  }
  
  static String getFormattedVersionInfo() {
    return VersionControl.getFormattedVersionInfo();
  }
  
  static bool isProductionEnvironment() {
    return VersionControl.environment == 'PROD';
  }
  
  static bool isStagingEnvironment() {
    return VersionControl.environment == 'SIT' || VersionControl.environment == 'UAT';
  }
  
  static bool isDevelopmentEnvironment() {
    return VersionControl.environment == 'DEV';
  }
}
