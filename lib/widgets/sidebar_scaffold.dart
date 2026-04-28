// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import '../services/auth_service.dart';
import '../providers/service_providers.dart';
import '../utils/app_icons.dart';
import 'background_image.dart';
import 'sidebar_version_display.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String iconName;
  final String route;
  final String? requiredPermission;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconName,
    required this.route,
    this.requiredPermission,
  });
}

class SidebarScaffold extends StatefulWidget {
  final Widget child;

  const SidebarScaffold({super.key, required this.child});

  @override
  State<SidebarScaffold> createState() => _SidebarScaffoldState();
}

class _SidebarScaffoldState extends State<SidebarScaffold> {
  bool _collapsed = false;
  static const double _sidebarWidth = 280;
  static const double _collapsedWidth = 80;

  // Navigation history tracking
  List<String> _navigationHistory = ['/dashboard'];
  int _historyIndex = 0;

  // Track navigation history
  void _updateNavigationHistory(String route) {
    if (_navigationHistory.isEmpty ||
        _navigationHistory[_historyIndex] != route) {
      // Remove any forward history when navigating to new route
      if (_historyIndex < _navigationHistory.length - 1) {
        _navigationHistory =
            _navigationHistory.take(_historyIndex + 1).toList();
      }
      // Never call setState from build path; this method is invoked from build.
      _navigationHistory.add(route);
      _historyIndex = _navigationHistory.length - 1;
    }
  }

  List<_NavItem> get _navItems {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final userRole =
        currentUser != null ? currentUser.role.toString().toLowerCase() : '';

    // Role-based navigation items
    final List<_NavItem> allItems = [
      // Core items for all authenticated users
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        iconName: 'dashboard',
        route: '/dashboard',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Projects',
        icon: Icons.folder_outlined,
        iconName: 'projects',
        route: '/projects',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Deliverables',
        icon: Icons.assignment_outlined,
        iconName: 'deliverables',
        route: '/deliverables-overview',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Timeline',
        icon: Icons.calendar_today_outlined,
        iconName: 'timeline',
        route: '/timeline',
        requiredPermission: null,
      ),
    ];

    // Role-specific items
    final List<_NavItem> roleSpecificItems = [];

    if (userRole.contains('admin') || userRole.contains('system')) {
      // Admin/System users get full access
      roleSpecificItems.addAll([
        const _NavItem(
          label: 'Sprints',
          icon: Icons.timer_outlined,
          iconName: 'sprints',
          route: '/sprints',
          requiredPermission: 'view_sprints',
        ),
        const _NavItem(
          label: 'Approval Requests',
          icon: Icons.assignment_outlined,
          iconName: 'approval_requests',
          route: '/approval-requests',
          requiredPermission: 'view_approvals',
        ),
        const _NavItem(
          label: 'Repository',
          icon: Icons.folder_outlined,
          iconName: 'repository',
          route: '/repository',
          requiredPermission: 'view_all_deliverables',
        ),
        const _NavItem(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          iconName: 'reports',
          route: '/report-repository',
          requiredPermission: 'view_all_deliverables',
        ),
        const _NavItem(
          label: 'Role Management',
          icon: Icons.admin_panel_settings_outlined,
          iconName: 'role_management',
          route: '/role-management',
          requiredPermission: 'manage_users',
        ),
        const _NavItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          iconName: 'settings',
          route: '/settings',
          requiredPermission: null,
        ),
      ]);
    } else if (userRole.contains('delivery') || userRole.contains('project')) {
      // Delivery/Project managers get project-related access
      roleSpecificItems.addAll([
        const _NavItem(
          label: 'Sprints',
          icon: Icons.timer_outlined,
          iconName: 'sprints',
          route: '/sprints',
          requiredPermission: 'view_sprints',
        ),
        const _NavItem(
          label: 'Approval Requests',
          icon: Icons.assignment_outlined,
          iconName: 'approval_requests',
          route: '/approval-requests',
          requiredPermission: 'view_approvals',
        ),
        const _NavItem(
          label: 'Repository',
          icon: Icons.folder_outlined,
          iconName: 'repository',
          route: '/repository',
          requiredPermission: 'view_all_deliverables',
        ),
        const _NavItem(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          iconName: 'reports',
          route: '/report-repository',
          requiredPermission: 'view_all_deliverables',
        ),
      ]);
    } else if (userRole.contains('client')) {
      // Client reviewers get focused access
      roleSpecificItems.addAll([
        const _NavItem(
          label: 'Approval Requests',
          icon: Icons.assignment_outlined,
          iconName: 'approval_requests',
          route: '/approval-requests',
          requiredPermission: 'view_approvals',
        ),
        const _NavItem(
          label: 'Repository',
          icon: Icons.folder_outlined,
          iconName: 'repository',
          route: '/repository',
          requiredPermission: 'view_all_deliverables',
        ),
        const _NavItem(
          label: 'Reports',
          icon: Icons.assessment_outlined,
          iconName: 'reports',
          route: '/report-repository',
          requiredPermission: 'view_all_deliverables',
        ),
      ]);
    }

    // Combine core items with role-specific items
    final combinedItems = [...allItems, ...roleSpecificItems];

    // Filter items based on user permissions
    return combinedItems.where((item) {
      // Special flag: hide from sidebar even if user has permission
      if (item.requiredPermission == 'HIDE_FROM_SIDEBAR') return false;

      // Client users should not see Projects and Deliverables
      if (userRole.contains('client') &&
          (item.label == 'Projects' || item.label == 'Deliverables')) {
        return false;
      }

      if (item.requiredPermission == null) return true;
      return authService.hasPermission(item.requiredPermission!);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _restoreSidebarState();
  }

  void _restoreSidebarState() {
    // Restore sidebar state from SharedPreferences or other storage
    // For now, we'll use a default state
    _collapsed = false;
  }

  void _persistSidebarState() {
    // Save sidebar state to SharedPreferences or other storage
    // Implementation would go here
  }

  void _toggleSidebar() {
    setState(() {
      _collapsed = !_collapsed;
    });
    _persistSidebarState();
  }

  bool get _isTeamMemberUser {
    final role = AuthService().currentUser?.role.toString().toLowerCase() ?? '';
    return role.contains('teammember') || role.contains('team_member');
  }

  Widget _buildTeamMemberSidebar({
    required bool isDarkMode,
    required String routeLocation,
  }) {
    final theme = Theme.of(context);
    final unselectedColor = isDarkMode
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.84);
    final welcomeTextColor = isDarkMode
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.82);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 760;
        final isVeryCompact = constraints.maxHeight < 660;
        final isUltraCompact = constraints.maxHeight < 580;

        final double sidebarChipSize =
            isUltraCompact ? 28 : (isVeryCompact ? 30 : (isCompact ? 32 : 36));
        final double sidebarIconSize =
            isUltraCompact ? 18 : (isVeryCompact ? 19 : (isCompact ? 21 : 23));
        final double navVerticalPadding =
            isUltraCompact ? 1.5 : (isVeryCompact ? 2 : 3);
        final double navFontSize =
            isUltraCompact ? 9.8 : (isVeryCompact ? 10.5 : 11.2);
        final double sectionGap = isUltraCompact ? 2 : (isVeryCompact ? 4 : 6);
        final double bottomGap = isUltraCompact ? 6 : (isVeryCompact ? 8 : 10);

        return Column(
          children: [
            SizedBox(height: isUltraCompact ? 4 : 8),
            Image.asset(
              'assets/icons/khono.png',
              width: isUltraCompact ? 150 : (isVeryCompact ? 190 : 228),
              height: isUltraCompact ? 28 : (isVeryCompact ? 35 : 44),
              fit: BoxFit.contain,
            ),
            SizedBox(height: isUltraCompact ? 4 : 6),
            Text(
              'Welcome to',
              style: TextStyle(
                color: welcomeTextColor,
                fontWeight: FontWeight.w600,
                fontSize: isUltraCompact ? 9.5 : (isVeryCompact ? 10.5 : 11),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Deliverable & Sprint Sign-Off Hub',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: welcomeTextColor,
                fontWeight: FontWeight.w600,
                fontSize: isUltraCompact ? 9.5 : (isVeryCompact ? 10.5 : 11),
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: sectionGap),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final active = routeLocation.startsWith(item.route);
                  final String? numberedIconAsset = index < 4
                      ? 'assets/Team_member_sidebar/${index + 1}.png'
                      : null;
                  final double numberedIconSize = sidebarIconSize * 1.6;
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: navVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color:
                          active ? const Color(0xFFC10D00) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (!routeLocation.startsWith(item.route)) {
                            context.go(item.route);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: isUltraCompact ? 6 : 8,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: sidebarChipSize,
                                height: sidebarChipSize,
                                child: Center(
                                  child: numberedIconAsset != null
                                      ? Image.asset(
                                          numberedIconAsset,
                                          width: numberedIconSize,
                                          height: numberedIconSize,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        )
                                      : AppIcons.getIconWidget(
                                          item.iconName,
                                          fallbackIcon: item.icon,
                                          isActive: active,
                                          size: sidebarIconSize,
                                          color: active
                                              ? Colors.white
                                              : unselectedColor,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        active ? Colors.white : unselectedColor,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: navFontSize,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: bottomGap),
            _buildSidebarBottomAction(
              label: 'Account Profile',
              iconName: 'account',
              fallbackIcon: Icons.person_outline,
              color: unselectedColor,
              onTap: () => context.go('/profile'),
              assetPath: 'assets/Team_member_sidebar/5.png',
              isActive: routeLocation.startsWith('/profile'),
            ),
            const SizedBox(height: 6),
            _buildSidebarBottomAction(
              label: 'Logout',
              iconName: 'logout',
              fallbackIcon: Icons.logout,
              color: unselectedColor,
              onTap: () => _handleLogout(context),
              assetPath: 'assets/Team_member_sidebar/6.png',
            ),
            SidebarVersionDisplay(isSidebarCollapsed: false),
          ],
        );
      },
    );
  }

  Widget _buildSidebarBottomAction({
    required String label,
    required String iconName,
    required IconData fallbackIcon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    String? assetPath,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC10D00) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              if (assetPath != null)
                SizedBox(
                  width: 28.8,
                  height: 28.8,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                )
              else
                AppIcons.getIconWidget(
                  iconName,
                  fallbackIcon: fallbackIcon,
                  isActive: isActive,
                  size: 18,
                  color: color,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.2,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor =
        isDarkMode ? FlownetColors.sidebarDark : FlownetColors.sidebarLight;
    final sidebarTextColor = isDarkMode ? Colors.white : Colors.black;
    final sidebarSubtleText =
        isDarkMode ? FlownetColors.textSecondary : Colors.black87;

    String routeLocation = '/';
    try {
      final router = GoRouter.maybeOf(context);
      final uri = router?.routeInformationProvider.value.uri;
      if (uri != null) {
        routeLocation = uri.path;
      } else {
        routeLocation = ModalRoute.of(context)?.settings.name ?? '/';
      }
    } catch (_) {
      routeLocation = ModalRoute.of(context)?.settings.name ?? '/';
    }
    final isDesktop = MediaQuery.of(context).size.width > 768;

    // Track navigation history
    _updateNavigationHistory(routeLocation);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundImage(
          child: Row(
            children: [
              // Sidebar with glassmorphism styling (Busisiwe branch look)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isTeamMemberUser
                    ? _sidebarWidth
                    : (_collapsed ? _collapsedWidth : _sidebarWidth),
                decoration: BoxDecoration(
                  color: sidebarColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.08 * 255).round()),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: _isTeamMemberUser
                        ? _buildTeamMemberSidebar(
                            isDarkMode: isDarkMode,
                            routeLocation: routeLocation,
                          )
                        : Column(
                            children: [
                              // Header with logo and collapse toggle
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  top: 24,
                                  bottom: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/Icons/Red_Khono_Discs.png',
                                      width: _collapsed ? 28 : 64,
                                      height: _collapsed ? 28 : 64,
                                      fit: BoxFit.contain,
                                    ),
                                    if (!_collapsed) const SizedBox(width: 40),
                                    if (!_collapsed)
                                      IconButton(
                                        onPressed: _toggleSidebar,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _collapsed
                                              ? Icons.chevron_right
                                              : Icons.chevron_left,
                                          color: sidebarSubtleText,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Navigation items (redesign branch styling)
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: _navItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _navItems[index];
                                    final active = routeLocation.startsWith(item.route);
                                    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                    final Color navText = isDarkMode ? Colors.white : const Color(0xFF141414);
                                    
                                    return Container(
                                      height: 32,
                                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: active ? const Color(0xFFD70E0E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!routeLocation.startsWith(item.route)) {
                                            context.go(item.route);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFE9E9E9),
                                                  shape: BoxShape.circle,
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                alignment: Alignment.center,
                                                child: AppIcons.getIconWidget(
                                                  item.iconName,
                                                  fallbackIcon: item.icon,
                                                  isActive: false,
                                                  size: 16,
                                                  color: const Color(0xFF121212),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.label,
                                                  style: TextStyle(
                                                    color: active ? Colors.white : navText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Column(
                                children: [
                                  _buildDesktopFooterItem(
                                    label: 'Account Profile',
                                    iconName: 'account',
                                    fallbackIcon: Icons.person_outline,
                                    currentRoute: routeLocation,
                                    textColor: isDarkMode ? Colors.white : const Color(0xFF141414),
                                    route: '/profile',
                                  ),
                                  _buildDesktopFooterItem(
                                    label: 'Logout',
                                    iconName: 'logout',
                                    fallbackIcon: Icons.logout,
                                    currentRoute: routeLocation,
                                    textColor: isDarkMode ? Colors.white : const Color(0xFF141414),
                                    onTap: () => _handleLogout(context),
                                  ),
                                ],
                              ),
                              SidebarVersionDisplay(
                                isSidebarCollapsed: _collapsed,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.child),
                      if (routeLocation != '/dashboard')
                        Positioned(
                          right: 20,
                          bottom: 96,
                          child: _buildThemeToggleButton(isDarkMode),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundImage(
          child: widget.child,
        ),
        floatingActionButton: routeLocation == '/dashboard'
            ? null
            : _buildThemeToggleButton(isDarkMode),
        drawer: Drawer(
          backgroundColor: sidebarColor,
          child: Column(
            children: [
              // Drawer header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: FlownetColors.coolGray,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/flownet_logo.png',
                      height: 32,
                      width: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Flow-Space',
                        style: TextStyle(
                          color: sidebarTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: sidebarTextColor),
                    ),
                  ],
                ),
              ),
              // Navigation items
              Expanded(
                child: _buildNavigationItems(isMobile: true),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNavigationItems({required bool isMobile}) {
    final routeLocation = GoRouterState.of(context).uri.path;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _navItems.length,
      itemBuilder: (context, index) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final sidebarTextColor = isDarkMode ? Colors.white : Colors.black;
        final sidebarSubtleText =
            isDarkMode ? FlownetColors.textSecondary : Colors.black87;
        final item = _navItems[index];
        final active = routeLocation.startsWith(item.route);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: AppIcons.getIconWidget(
              item.iconName,
              fallbackIcon: item.icon,
              isActive: active,
              size: 24,
              color: active ? sidebarTextColor : sidebarSubtleText,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: active ? sidebarTextColor : sidebarSubtleText,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            onTap: () {
              if (!routeLocation.startsWith(item.route)) {
                context.go(item.route);
                Navigator.pop(context); // Close drawer on mobile
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildThemeToggleButton(bool isDarkMode) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: () {
        ProviderScope.containerOf(context, listen: false)
            .read(themeProvider.notifier)
            .toggleTheme();
      },
      backgroundColor: isDarkMode ? FlownetColors.sidebarDark : FlownetColors.sidebarLight,
      foregroundColor: isDarkMode ? Colors.white : Colors.black,
      child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
    );
  }

  Future<void> _handleLogout(BuildContext ctx) async {
    final router = GoRouter.of(ctx);
    await AuthService().signOut();
    if (!mounted) return;
    router.go('/');
  }

  Widget _buildDesktopFooterItem({
    required String label,
    required String iconName,
    required IconData fallbackIcon,
    required String currentRoute,
    required Color textColor,
    String? route,
    VoidCallback? onTap,
  }) {
    final bool active = route != null && currentRoute.startsWith(route);
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD70E0E) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }
          if (route != null && !currentRoute.startsWith(route)) {
            context.go(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E9E9),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: AppIcons.getIconWidget(
                  iconName,
                  fallbackIcon: fallbackIcon,
                  isActive: false,
                  size: 16,
                  color: const Color(0xFF121212),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
