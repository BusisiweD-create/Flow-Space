import 'package:flutter/material.dart';

/// Utility class for managing app icons
/// Provides a centralized way to get icons by name with fallback support
class AppIcons {
  /// Get icon by name, with fallback to provided icon
  /// 
  /// [iconName] - The name of the icon to retrieve
  /// [fallbackIcon] - The icon to use if iconName is not found
  /// [size] - Optional size for the icon
  /// [color] - Optional color for the icon
  static IconData getIcon(
    String iconName, {
    required IconData fallbackIcon,
    double? size,
    Color? color,
  }) {
    // Map of icon names to IconData
    // This allows for custom icon mapping if needed in the future
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
    };

    // Return mapped icon or fallback
    return iconMap[iconName] ?? fallbackIcon;
  }

  /// Get icon widget by name
  static Widget getIconWidget(
    String iconName, {
    required IconData fallbackIcon,
    double size = 24.0,
    Color? color,
  }) {
    return Icon(
      getIcon(iconName, fallbackIcon: fallbackIcon),
      size: size,
      color: color,
    );
  }
}

