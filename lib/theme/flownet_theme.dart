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
      textTheme: TextTheme(
        // Headings - Montserrat Bold
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),

        // Body text - Open Sans Regular
        bodyLarge: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: FlownetColors.pureWhite,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: FlownetColors.pureWhite,
        ),
        bodySmall: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: FlownetColors.coolGray,
        ),

        // Labels
        labelLarge: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FlownetColors.pureWhite,
        ),
        labelMedium: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FlownetColors.pureWhite,
        ),
        labelSmall: GoogleFonts.openSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FlownetColors.coolGray,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlownetColors.pureWhite,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: FlownetColors.graphiteGray,
        elevation: 4,
        shadowColor: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
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
          shadowColor: FlownetColors.crimsonRed.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            FlownetColors.crimsonRed.withValues(alpha: 0.1),
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
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            FlownetColors.slate.withValues(alpha: 0.1),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FlownetColors.crimsonRed,
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
        hintStyle: GoogleFonts.openSans(
          color: FlownetColors.coolGray,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.openSans(
          color: FlownetColors.coolGray,
          fontSize: 16,
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
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FlownetColors.charcoalBlack,
        selectedIconTheme: const IconThemeData(
          color: FlownetColors.crimsonRed,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: FlownetColors.coolGray,
          size: 24,
        ),
        selectedLabelTextStyle: GoogleFonts.openSans(
          color: FlownetColors.crimsonRed,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.openSans(
          color: FlownetColors.coolGray,
          fontWeight: FontWeight.normal,
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
        titleTextStyle: GoogleFonts.openSans(
          color: FlownetColors.pureWhite,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.openSans(
          color: FlownetColors.coolGray,
          fontSize: 14,
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
}
