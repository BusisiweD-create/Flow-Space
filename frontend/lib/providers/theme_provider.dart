// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend_settings_service.dart';
import './api_auth_riverpod_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeFromLocalStorage();
  }

  Future<void> _loadThemeFromLocalStorage() async {
    // Load theme from local storage only (for initial app startup)
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('dark_mode') ?? false;
    final useSystemTheme = prefs.getBool('use_system_theme') ?? false;
    
    if (useSystemTheme) {
      state = ThemeMode.system;
    } else {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> _loadTheme() async {
    try {
      // Try to load from backend if authenticated
      final settings = await BackendSettingsService.getUserSettings();
      final isDarkMode = settings['dark_mode'] ?? false;
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      
      // Also update local storage with backend settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDarkMode);
      await prefs.setBool('use_system_theme', false);
    } catch (e) {
      // Fallback to local storage if backend fails or user not authenticated
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('dark_mode') ?? false;
      final useSystemTheme = prefs.getBool('use_system_theme') ?? false;
      
      if (useSystemTheme) {
        state = ThemeMode.system;
      } else {
        state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    }
  }

  Future<void> toggleTheme() async {
    ThemeMode newMode;
    
    // Cycle through themes: system -> light -> dark -> system
    if (state == ThemeMode.system) {
      newMode = ThemeMode.light;
    } else if (state == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else {
      newMode = ThemeMode.system;
    }
    
    state = newMode;
    
    // Save to both backend and local storage
    final isDarkMode = newMode == ThemeMode.dark;
    final isSystemTheme = newMode == ThemeMode.system;
    
    try {
      await BackendSettingsService.setDarkMode(isDarkMode);
    } catch (e) {
      // If backend fails, save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDarkMode);
    }
    
    // Also save system theme preference locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_theme', isSystemTheme);
  }

  Future<void> setTheme(bool isDarkMode) async {
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    
    try {
      await BackendSettingsService.setDarkMode(isDarkMode);
    } catch (e) {
      // If backend fails, save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDarkMode);
    }
  }

  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    
    // Save system theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_theme', true);
    
    // Also update backend with current system theme
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    try {
      await BackendSettingsService.setDarkMode(isDarkMode);
    } catch (e) {
      // If backend fails, save to local storage
      await prefs.setBool('dark_mode', isDarkMode);
    }
  }

  bool get isDarkMode {
    if (state == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  String get themeName {
    switch (state) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> refreshThemeFromBackend() async {
    await _loadTheme();
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final themeNotifier = ThemeNotifier();
  
  // Watch authentication state and refresh theme when user logs in
  ref.listen<ApiAuthState>(apiAuthProvider, (previous, next) {
    if (next.user != null && (previous?.user == null || previous!.user != next.user)) {
      // User just logged in, refresh theme from backend
      themeNotifier.refreshThemeFromBackend();
    }
  });
  
  return themeNotifier;
});

class AppThemes {
  // Primary brand colors
  static const Color primaryColor = Color(0xFF2563EB); // Professional blue
  static const Color secondaryColor = Color(0xFF64748B); // Slate gray
  static const Color accentColor = Color(0xFF0EA5E9); // Sky blue
  static const Color successColor = Color(0xFF10B981); // Emerald green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnBackground = Color(0xFF475569);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnBackground = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF334155);

  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurface,
      background: lightBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightOnSurface,
      onBackground: lightOnBackground,
      error: errorColor,
    ),
    brightness: Brightness.light,
    useMaterial3: true,
    
    // App bar
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightOnSurface,
      elevation: 1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: lightBorder.withOpacity(0.5),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: lightBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),
    
    // Progress indicators
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: lightBorder,
    ),
    
    // Text themes
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightOnSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightOnSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: lightOnSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightOnSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: lightOnSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightOnSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: lightOnBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: lightOnBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: lightOnBackground,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      background: darkBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkOnSurface,
      onBackground: darkOnBackground,
      error: errorColor,
    ),
    brightness: Brightness.dark,
    useMaterial3: true,
    
    // App bar
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkOnSurface,
      elevation: 1,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: darkBorder.withOpacity(0.5),
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: darkBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    
    // Progress indicators
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: darkBorder,
    ),
    
    // Text themes
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkOnSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkOnSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkOnSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkOnSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkOnSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkOnSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkOnBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkOnBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: darkOnBackground,
      ),
    ),
  );
}