import 'package:flutter/material.dart';

/// Centralized icon mapping for both Material icons and asset-based sidebar icons.
class AppIcons {
  /// Get Material icon by logical name, with fallback to provided icon.
  ///
  /// This keeps backwards compatibility for places still using IconData.
  static IconData getIcon(
    String iconName, {
    required IconData fallbackIcon,
    double? size,
    Color? color,
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
      'account': Icons.person_outline,
    };

    return iconMap[iconName] ?? fallbackIcon;
  }

  /// Get icon widget by Material name (legacy API).
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

  /// Sidebar-specific dual-state asset mapping.
  ///
  /// NOTE: Filenames intentionally mirror the real assets in `assets/icons/`
  /// and are case- and space-sensitive.
  static const String _dashboardDefault = 'assets/icons/Group 299.png';
  static const String _dashboardActive = 'assets/icons/Group 301.png';

  static const String _sprintsDefault = 'assets/icons/Group 268.png';
  static const String _sprintsActive = 'assets/icons/Group 286.png';

  static const String _notificationsDefault = 'assets/icons/Group 282.png';
  static const String _notificationsActive = 'assets/icons/Group 284.png';

  static const String _approvalsDefault = 'assets/icons/Group 211.png';
  static const String _approvalsActive = 'assets/icons/Group 221.png';

  static const String _repositoryDefault = 'assets/icons/Group 232.png';
  static const String _repositoryActive = 'assets/icons/Group 308.png';

  static const String _accountDefault = 'assets/icons/Group 311.png';
  static const String _accountActive = 'assets/icons/Group 173.png';

  static const String _logoutDefault = 'assets/icons/Group 288.png';
  static const String _logoutActive = 'assets/icons/Group 217.png';

  /// Returns the asset path for a sidebar icon based on its key and active state.
  ///
  /// [key] should be one of:
  /// - 'dashboard'
  /// - 'sprints'
  /// - 'notifications'
  /// - 'approvals'
  /// - 'repository'
  /// - 'account'
  /// - 'logout'
  static String sidebarIconAsset(String key, {required bool active}) {
    switch (key) {
      case 'dashboard':
        return active ? _dashboardActive : _dashboardDefault;
      case 'sprints':
        return active ? _sprintsActive : _sprintsDefault;
      case 'notifications':
        return active ? _notificationsActive : _notificationsDefault;
      case 'approvals':
        return active ? _approvalsActive : _approvalsDefault;
      case 'repository':
        return active ? _repositoryActive : _repositoryDefault;
      case 'account':
        return active ? _accountActive : _accountDefault;
      case 'logout':
        return active ? _logoutActive : _logoutDefault;
      default:
        return active ? _dashboardActive : _dashboardDefault;
    }
  }
}

