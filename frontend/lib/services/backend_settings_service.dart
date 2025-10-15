// ignore_for_file: avoid_print, unused_element, duplicate_ignore

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'api_service.dart';

class BackendSettingsService {
  static const String _userIdKey = 'current_user_id';

  // Get current user ID from shared preferences
  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  // Save user ID to shared preferences
  // ignore: unused_element
  static Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Get user settings from backend
  static Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/settings/me'),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // If settings don't exist, return default settings
        final userId = await _getUserId();
        if (userId == null) {
          // Return default settings without user ID if not logged in
          return _getDefaultSettings('anonymous');
        }
        return _getDefaultSettings(userId);
      }
    } catch (e) {
      print('Error fetching settings from backend: $e');
      // Fallback to local storage if backend is unavailable
      return _getLocalSettings();
    }
  }

  // Update user settings in backend
  static Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/settings/me'),
        headers: await ApiService.getAuthHeaders(),
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        final updatedSettings = json.decode(response.body);
        // Also save to local storage for offline use
        await _saveLocalSettings(updatedSettings);
        return updatedSettings;
      } else {
        throw Exception('Failed to update settings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating settings in backend: $e');
      // Fallback to local storage if backend is unavailable
      await _saveLocalSettings(settings);
      return settings;
    }
  }

  // Get default settings structure
  static Map<String, dynamic> _getDefaultSettings(String userId) {
    return {
      'user_id': userId,
      'dark_mode': false,
      'notifications_enabled': true,
      'language': 'English',
      'sync_on_mobile_data': false,
      'auto_backup': false,
      'share_analytics': false,
      'allow_notifications': true,
    };
  }

  // Get settings from local storage
  static Future<Map<String, dynamic>> _getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getUserId();
    return {
      'user_id': userId ?? 'anonymous',
      'dark_mode': prefs.getBool('dark_mode') ?? false,
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'language': prefs.getString('language') ?? 'English',
      'sync_on_mobile_data': prefs.getBool('sync_on_mobile_data') ?? false,
      'auto_backup': prefs.getBool('auto_backup') ?? false,
      'share_analytics': prefs.getBool('share_analytics') ?? false,
      'allow_notifications': prefs.getBool('allow_notifications') ?? true,
    };
  }

  // Save settings to local storage
  static Future<void> _saveLocalSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', settings['dark_mode'] ?? false);
    await prefs.setBool('notifications_enabled', settings['notifications_enabled'] ?? true);
    await prefs.setString('language', settings['language'] ?? 'English');
    await prefs.setBool('sync_on_mobile_data', settings['sync_on_mobile_data'] ?? false);
    await prefs.setBool('auto_backup', settings['auto_backup'] ?? false);
    await prefs.setBool('share_analytics', settings['share_analytics'] ?? false);
    await prefs.setBool('allow_notifications', settings['allow_notifications'] ?? true);
  }

  // Individual getter methods for convenience
  static Future<bool> getDarkMode() async {
    final settings = await getUserSettings();
    return settings['dark_mode'] ?? false;
  }

  static Future<bool> getNotificationsEnabled() async {
    final settings = await getUserSettings();
    return settings['notifications_enabled'] ?? true;
  }

  static Future<String> getLanguage() async {
    final settings = await getUserSettings();
    return settings['language'] ?? 'English';
  }

  static Future<bool> getSyncOnMobileData() async {
    final settings = await getUserSettings();
    return settings['sync_on_mobile_data'] ?? false;
  }

  static Future<bool> getAutoBackup() async {
    final settings = await getUserSettings();
    return settings['auto_backup'] ?? false;
  }

  static Future<bool> getShareAnalytics() async {
    final settings = await getUserSettings();
    return settings['share_analytics'] ?? false;
  }

  static Future<bool> getAllowNotifications() async {
    final settings = await getUserSettings();
    return settings['allow_notifications'] ?? true;
  }

  // Individual setter methods for convenience
  static Future<void> setDarkMode(bool value) async {
    final settings = await getUserSettings();
    settings['dark_mode'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final settings = await getUserSettings();
    settings['notifications_enabled'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setLanguage(String value) async {
    final settings = await getUserSettings();
    settings['language'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setSyncOnMobileData(bool value) async {
    final settings = await getUserSettings();
    settings['sync_on_mobile_data'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setAutoBackup(bool value) async {
    final settings = await getUserSettings();
    settings['auto_backup'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setShareAnalytics(bool value) async {
    final settings = await getUserSettings();
    settings['share_analytics'] = value;
    await updateUserSettings(settings);
  }

  static Future<void> setAllowNotifications(bool value) async {
    final settings = await getUserSettings();
    settings['allow_notifications'] = value;
    await updateUserSettings(settings);
  }

  // Batch update multiple settings at once
  static Future<void> updateMultipleSettings(Map<String, dynamic> updates) async {
    final settings = await getUserSettings();
    settings.addAll(updates);
    await updateUserSettings(settings);
  }
}
