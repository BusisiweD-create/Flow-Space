// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlownetColors {
  // Primary Colors
  static const Color crimsonRed = Color(0xFFC8102E);
  static const Color charcoalBlack = Color(0xFF1A1A1A);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color graphiteGray = Color(0xFF2E2E2E);
  static const Color coolGray = Color(0xFFB3B3B3);
  static const Color slate = Color(0xFF444444);

  // Accent Colors
  static const Color electricBlue = Color(0xFF0077B6);
  static const Color emeraldGreen = Color(0xFF28A745);
  static const Color amberOrange = Color(0xFFFF8800);
  static const Color purple = Color(0xFF6F42C1);
  static const Color red = Color(0xFFDC3545);
  static const Color teal = Color(0xFF20C997);

  // Dark theme specific
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF2E2E2E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFB3B3B3);

  // Success and Accent Colors
  static const Color successGreen = Color(0xFF28A745);
  static const Color deepNavy = Color(0xFF0A2463);
}

class FlownetTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: FlownetColors.crimsonRed,
        onPrimary: FlownetColors.pureWhite,
        secondary: FlownetColors.slate,
        onSecondary: FlownetColors.pureWhite,
        surface: FlownetColors.darkSurface,
        onSurface: FlownetColors.darkOnSurface,
        surfaceContainerHighest: FlownetColors.darkSurfaceVariant,
        onSurfaceVariant: FlownetColors.darkOnSurfaceVariant,
        error: FlownetColors.crimsonRed,
        onError: FlownetColors.pureWhite,
        outline: FlownetColors.slate,
        outlineVariant: FlownetColors.coolGray,
      ),

      // Typography
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        // Headings - Poppins Bold
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),

        // Body text - Poppins Regular
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: FlownetColors.coolGray,
          fontFamily: 'Poppins',
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FlownetColors.coolGray,
          fontFamily: 'Poppins',
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: FlownetColors.graphiteGray,
        elevation: 4,
        shadowColor: FlownetColors.charcoalBlack.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FlownetColors.crimsonRed,
          foregroundColor: FlownetColors.pureWhite,
          elevation: 2,
          shadowColor: FlownetColors.crimsonRed.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            FlownetColors.crimsonRed.withOpacity(0.1),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FlownetColors.pureWhite,
          side: const BorderSide(color: FlownetColors.slate, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            FlownetColors.slate.withOpacity(0.1),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FlownetColors.crimsonRed,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FlownetColors.graphiteGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FlownetColors.slate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FlownetColors.slate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FlownetColors.crimsonRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FlownetColors.crimsonRed),
        ),
        hintStyle: const TextStyle(
          color: FlownetColors.coolGray,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: FlownetColors.coolGray,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: FlownetColors.pureWhite,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: FlownetColors.slate,
        thickness: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FlownetColors.charcoalBlack,
        selectedItemColor: FlownetColors.crimsonRed,
        unselectedItemColor: FlownetColors.coolGray,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FlownetColors.crimsonRed,
        foregroundColor: FlownetColors.pureWhite,
        elevation: 4,
      ),

      // Navigation Rail Theme
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: FlownetColors.charcoalBlack,
        selectedIconTheme: IconThemeData(
          color: FlownetColors.crimsonRed,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: FlownetColors.coolGray,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: FlownetColors.crimsonRed,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: FlownetColors.coolGray,
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
      ),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: FlownetColors.charcoalBlack,
        elevation: 16,
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        tileColor: FlownetColors.graphiteGray,
        selectedTileColor: FlownetColors.crimsonRed.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          color: FlownetColors.pureWhite,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        subtitleTextStyle: const TextStyle(
          color: FlownetColors.coolGray,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Utility method for status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'approved':
      case 'completed':
        return FlownetColors.emeraldGreen;
      case 'warning':
      case 'pending':
        return FlownetColors.amberOrange;
      case 'error':
      case 'denied':
      case 'failed':
        return FlownetColors.crimsonRed;
      case 'info':
      case 'active':
        return FlownetColors.electricBlue;
      default:
        return FlownetColors.coolGray;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: FlownetColors.crimsonRed,
        onPrimary: FlownetColors.pureWhite,
        secondary: FlownetColors.electricBlue,
        onSecondary: FlownetColors.pureWhite,
        surface: FlownetColors.pureWhite,
        onSurface: FlownetColors.charcoalBlack,
        surfaceContainerHighest: Color(0xFFF5F5F5),
        onSurfaceVariant: FlownetColors.graphiteGray,
        error: FlownetColors.crimsonRed,
        onError: FlownetColors.pureWhite,
        outline: Color(0xFFE0E0E0),
        outlineVariant: FlownetColors.coolGray,
      ),

      // Typography
      textTheme: const TextTheme(
        // Headings - Poppins Bold
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),

        // Body text - Poppins Regular
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: FlownetColors.graphiteGray,
          fontFamily: 'Poppins',
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FlownetColors.graphiteGray,
          fontFamily: 'Poppins',
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: FlownetColors.pureWhite,
        foregroundColor: FlownetColors.charcoalBlack,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.charcoalBlack,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: FlownetColors.pureWhite,
        elevation: 2,
        // ignore: deprecated_member_use
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FlownetColors.crimsonRed,
          foregroundColor: FlownetColors.pureWhite,
          elevation: 2,
          shadowColor: FlownetColors.crimsonRed.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            FlownetColors.crimsonRed.withOpacity(0.1),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FlownetColors.charcoalBlack,
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.black.withOpacity(0.05),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FlownetColors.crimsonRed,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FlownetColors.crimsonRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FlownetColors.crimsonRed),
        ),
        hintStyle: const TextStyle(
          color: FlownetColors.graphiteGray,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: FlownetColors.graphiteGray,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: FlownetColors.charcoalBlack,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FlownetColors.pureWhite,
        selectedItemColor: FlownetColors.crimsonRed,
        unselectedItemColor: FlownetColors.graphiteGray,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FlownetColors.crimsonRed,
        foregroundColor: FlownetColors.pureWhite,
        elevation: 4,
      ),

      // Navigation Rail Theme
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: FlownetColors.pureWhite,
        selectedIconTheme: IconThemeData(
          color: FlownetColors.crimsonRed,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: FlownetColors.graphiteGray,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: FlownetColors.crimsonRed,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: FlownetColors.graphiteGray,
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
      ),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: FlownetColors.pureWhite,
        elevation: 16,
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        tileColor: FlownetColors.pureWhite,
        selectedTileColor: FlownetColors.crimsonRed.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          color: FlownetColors.charcoalBlack,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        subtitleTextStyle: const TextStyle(
          color: FlownetColors.graphiteGray,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
