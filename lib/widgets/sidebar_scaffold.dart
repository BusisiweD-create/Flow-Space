import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import 'flownet_logo.dart';
import '../services/auth_service.dart';
import '../utils/app_icons.dart';
import 'glass/glass_panel.dart';
import 'glass/glass_button.dart';

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

  List<_NavItem> get _navItems {
    final authService = AuthService();
    final allItems = [
      _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        iconKey: 'dashboard',
        route: '/dashboard',
        requiredPermission: null,
      ),
      _NavItem(
        label: 'Resource Allocation',
        icon: Icons.timer_outlined,
        iconKey: 'sprints',
        route: '/sprint-console',
        requiredPermission: 'manage_sprints',
      ),
      _NavItem(
        label: 'Approvals',
        icon: Icons.check_box_outlined,
        iconKey: 'approvals',
        route: '/approvals',
        requiredPermission: 'approve_deliverable',
      ),
      _NavItem(
        label: 'Project Data',
        icon: Icons.folder_outlined,
        iconKey: 'repository',
        route: '/repository',
        requiredPermission: 'view_all_deliverables',
      ),
      _NavItem(
        label: 'Reports',
        icon: Icons.assessment_outlined,
        iconKey: 'reports',
        route: '/report-repository',
        requiredPermission: 'view_team_dashboard',
      ),
      _NavItem(
        label: 'User Management',
        icon: Icons.admin_panel_settings_outlined,
        iconKey: 'role_management',
        route: '/role-management',
        requiredPermission: 'manage_users',
      ),
    ];

    // Filter items based on user permissions
    return allItems.where((item) {
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

  @override
  Widget build(BuildContext context) {
    final routeLocation = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF05040A),
              Color(0xFF14121B),
              FlownetColors.charcoalBlack,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/backgrounds/luxury_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: FlownetColors.charcoalBlack);
              },
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
            Row(
              children: [
                SizedBox(
                  width: _collapsed ? _collapsedWidth : _sidebarWidth,
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment:
                          _collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FlownetLogo(
                              showText: false,
                              width: 32,
                              height: 32,
                            ),
                            if (!_collapsed) const SizedBox(width: 12),
                            if (!_collapsed)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'FLOWNET',
                                      style: TextStyle(
                                        color: FlownetColors.pureWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Welcome back',
                                      style: TextStyle(
                                        color: FlownetColors.coolGray,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            IconButton(
                              onPressed: _toggleSidebar,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                _collapsed ? Icons.chevron_right : Icons.chevron_left,
                                color: FlownetColors.coolGray,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _navItems.length,
                            itemBuilder: (context, index) {
                              final item = _navItems[index];
                              final active = routeLocation.startsWith(item.route);
                              final iconPath = AppIcons.sidebarIconAsset(
                                item.iconKey,
                                active: active,
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                // Provide a Material ancestor for InkWell to fix
                                // "No Material widget found" runtime errors.
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    if (!routeLocation.startsWith(item.route)) {
                                      context.go(item.route);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: active
                                          ? FlownetColors.crimsonRed
                                              .withValues(alpha: 0.22)
                                          : Colors.white.withValues(alpha: 0.03),
                                      border: Border.all(
                                        color: active
                                            ? FlownetColors.crimsonRed
                                                .withValues(alpha: 0.6)
                                            : Colors.white.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withValues(
                                              alpha: active ? 0.4 : 0.3,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: active ? 0.5 : 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Image.asset(
                                              iconPath,
                                              fit: BoxFit.contain,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                return Icon(
                                                  item.icon,
                                                  size: 18,
                                                  color: FlownetColors.coolGray,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        if (!_collapsed) const SizedBox(width: 12),
                                        if (!_collapsed)
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style: TextStyle(
                                                color: active
                                                    ? FlownetColors.pureWhite
                                                    : FlownetColors.coolGray,
                                                fontWeight: active
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_collapsed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GlassButton(
                                  onPressed: () {
                                    if (!routeLocation.startsWith('/profile')) {
                                      context.go('/profile');
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.4),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Image.asset(
                                            AppIcons.sidebarIconAsset(
                                              'account',
                                              active: false,
                                            ),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Profile'),
                                    ],
                                  ),
                                ),
                              ),
                            GlassButton(
                              isDestructive: true,
                              onPressed: () => _handleSidebarLogout(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Image.asset(
                                        AppIcons.sidebarIconAsset(
                                          'logout',
                                          active: false,
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Logout'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        if (routeLocation != '/dashboard')
                          GlassPanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            borderRadius: 20,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () {
                                    if (GoRouter.of(context).canPop()) {
                                      GoRouter.of(context).pop();
                                    } else {
                                      GoRouter.of(context).go('/dashboard');
                                    }
                                  },
                                  tooltip: 'Back',
                                  color: FlownetColors.pureWhite,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Forward navigation coming soon',
                                        ),
                                        backgroundColor:
                                            FlownetColors.amberOrange,
                                      ),
                                    );
                                  },
                                  tooltip: 'Forward',
                                  color: FlownetColors.pureWhite,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getPageTitle(routeLocation),
                                  style: const TextStyle(
                                    color: FlownetColors.pureWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: GlassPanel(
                              padding: const EdgeInsets.all(24),
                              borderRadius: 28,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        backgroundColor: FlownetColors.charcoalBlack,
        appBar: AppBar(
          title: const FlownetLogo(showText: false),
          centerTitle: false,
          actions: [
            if (routeLocation != '/dashboard')
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: FlownetColors.charcoalBlack,
          child: SafeArea(
            child: Column(
              children: [
                const Center(child: FlownetLogo(showText: true)),
                const Divider(color: FlownetColors.slate),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final active = routeLocation.startsWith(item.route);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,),
                        decoration: BoxDecoration(
                          color: active
                              ? FlownetColors.crimsonRed.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: active
                              ? const Border(
                                  left: BorderSide(
                                    color: FlownetColors.crimsonRed,
                                    width: 4,
                                  ),
                                )
                              : null,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(
                                alpha: active ? 0.4 : 0.3,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                AppIcons.sidebarIconAsset(
                                  item.iconKey,
                                  active: active,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: active
                                  ? FlownetColors.crimsonRed
                                  : FlownetColors.pureWhite,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (!routeLocation.startsWith(item.route)) {
                              context.go(item.route);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: FlownetColors.charcoalBlack,
          ),
          child: Column(
            children: [
              // Top navigation bar with back/forward buttons
              if (routeLocation != '/dashboard')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,),
                  decoration: const BoxDecoration(
                    color: FlownetColors.graphiteGray,
                    border: Border(
                      bottom: BorderSide(
                          color: FlownetColors.slate, width: 1,),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                        color: FlownetColors.pureWhite,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          // Forward navigation logic (can be enhanced)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Forward navigation coming soon',),
                              backgroundColor:
                                  FlownetColors.amberOrange,
                            ),
                          );
                        },
                        tooltip: 'Forward',
                        color: FlownetColors.pureWhite,
                      ),
                      const Spacer(),
                      // Current page indicator
                      Text(
                        _getPageTitle(routeLocation),
                        style: const TextStyle(
                          color: FlownetColors.coolGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      );
    }
  }

  String _getPageTitle(String route) {
    switch (route) {
      case '/approvals':
        return 'Approvals';
      case '/notifications':
        return 'Notifications';
      case '/repository':
        return 'Repository';
      case '/report-repository':
        return 'Report Repository';
      case '/sprint-console':
        return 'Sprint Console';
      case '/role-management':
        return 'User Management';
      case '/profile':
        return 'Profile & Settings';
      default:
        return 'Flownet Workspaces';
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String iconKey;
  final String route;
  final String? requiredPermission;

  _NavItem({
    required this.label,
    required this.icon,
    required this.iconKey,
    required this.route,
    this.requiredPermission,
  });
}

Future<void> _handleSidebarLogout(BuildContext context) async {
  final authService = AuthService();
  final router = GoRouter.of(context);

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: FlownetColors.charcoalBlack,
      title: const Text(
        'Logout',
        style: TextStyle(color: FlownetColors.pureWhite),
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(color: FlownetColors.coolGray),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: FlownetColors.coolGray),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await authService.signOut();
            router.go('/login');
          },
          child: const Text(
            'Logout',
            style: TextStyle(color: FlownetColors.crimsonRed),
          ),
        ),
      ],
    ),
  );
}
