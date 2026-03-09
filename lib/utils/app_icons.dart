import 'package:flutter/material.dart';

/// Utility class for managing app icons.
/// Provides a centralized way to get icons by name with fallback support.
class AppIcons {
  static String _getIconPath(String iconName, bool isActive) {
    // Map app iconName keys to the exact icon filenames.
    // NOTE: icon files use a double extension: *.png.png
    final iconPaths = <String, Map<String, String>>{
      'dashboard': {
        'active': 'assets/icons/Dashboard active.png.png',
        'inactive': 'assets/icons/Dashboard inactive.png.png',
      },
      'sprints': {
        'active': 'assets/icons/Sprints console active.png.png',
        'inactive': 'assets/icons/Sprints console inactive.png.png',
      },
      'notifications': {
        'active': 'assets/icons/Notifications active.png.png',
        'inactive': 'assets/icons/Notifications inactive.png.png',
      },
      'repository': {
        'active': 'assets/icons/Repository_Project active.png.png',
        'inactive': 'assets/icons/Repository_Project inactive.png.png',
      },
      'approval_requests': {
        'active': 'assets/icons/Approval Requests active.png.png',
        'inactive': 'assets/icons/Approval Requests inactive.png.png',
      },
      'approvals': {
        'active': 'assets/icons/Data_Approvals active.png.png',
        'inactive': 'assets/icons/Data_Approvals inactive.png.png',
      },
      'reports': {
        'active': 'assets/icons/Reports active.png.png',
        'inactive': 'assets/icons/Reports inactive.png.png',
      },
      'role_management': {
        'active': 'assets/icons/Role Managemet active.png.png',
        'inactive': 'assets/icons/Role Managemet inactive.png.png',
      },
      'settings': {
        'active': 'assets/icons/Settings active.png.png',
        'inactive': 'assets/icons/Settings inactive.png.png',
      },
      'account': {
        'active': 'assets/icons/Profile page active.png.png',
        'inactive': 'assets/icons/Profile page inactive.png.png',
      },
      'logout': {
        'active': 'assets/icons/Logout button active.png.png',
        'inactive': 'assets/icons/Logout button inactive.png.png',
      },
      'timeline': {
        'active': 'assets/icons/Timeline Page active.png.png',
        'inactive': 'assets/icons/Timeline Page inactive.png.png',
      },
      'teams': {
        'active': 'assets/icons/Home_Dashboard active.png.png',
        'inactive': 'assets/icons/Home_Dashboard inactive.png.png',
      },
      'urgent_notifications': {
        'active': 'assets/icons/Urgent Notifications active.png.png',
        'inactive': 'assets/icons/Urgent Notifications inactive.png.png',
      },
    };

    final paths = iconPaths[iconName];
    if (paths == null) return '';
    return isActive ? paths['active']! : paths['inactive']!;
  }

  /// Get icon by name, with fallback to provided icon.
  static IconData getIcon(
    String iconName, {
    required IconData fallbackIcon,
  }) {
    final iconMap = <String, IconData>{
      'dashboard': Icons.dashboard_outlined,
      'sprints': Icons.timer_outlined,
      'notifications': Icons.notifications_outlined,
      'approvals': Icons.check_box_outlined,
      'approval_requests': Icons.assignment_outlined,
      'repository': Icons.folder_outlined,
      'reports': Icons.assessment_outlined,
      'role_management': Icons.admin_panel_settings_outlined,
      'settings': Icons.settings_outlined,
      'account': Icons.person_outline,
      'timeline': Icons.calendar_today_outlined,
    };

    return iconMap[iconName] ?? fallbackIcon;
  }

  /// Get icon widget by name.
  static Widget getIconWidget(
    String iconName, {
    required IconData fallbackIcon,
    bool isActive = false,
    double size = 24.0,
    Color? color,
  }) {
    final assetPath = _getIconPath(iconName, isActive);
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Failed to load icon asset: $assetPath -> $error');
          return Icon(
            getIcon(iconName, fallbackIcon: fallbackIcon),
            size: size,
            color: color,
          );
        },
      );
    }

    return Icon(
      getIcon(iconName, fallbackIcon: fallbackIcon),
      size: size,
      color: color,
    );
  }
}
