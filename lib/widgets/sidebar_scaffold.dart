import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import 'flownet_logo.dart';
import '../services/auth_service.dart';

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
      const _NavItem(
        label: 'Dashboard', 
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
        requiredPermission: null, // All authenticated users can access dashboard
      ),
      const _NavItem(
        label: 'Sprints', 
        icon: Icons.timer_outlined, 
        route: '/sprint-console',
        requiredPermission: 'manage_sprints',
      ),
      const _NavItem(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        route: '/notifications',
        requiredPermission: null, // All users can access notifications
      ),
      const _NavItem(
        label: 'Approvals',
        icon: Icons.check_box_outlined,
        route: '/approvals',
        requiredPermission: 'approve_deliverable',
      ),
      const _NavItem(
        label: 'Approval Requests',
        icon: Icons.assignment_outlined,
        route: '/approval-requests',
        requiredPermission: 'approve_deliverable',
      ),
      const _NavItem(
        label: 'Repository', 
        icon: Icons.folder_outlined, 
        route: '/repository',
        requiredPermission: 'view_all_deliverables',
      ),
      const _NavItem(
        label: 'Reports', 
        icon: Icons.assessment_outlined, 
        route: '/report-repository',
        requiredPermission: 'view_team_dashboard',
      ),
      const _NavItem(
        label: 'Role Management',
        icon: Icons.admin_panel_settings_outlined,
        route: '/role-management',
        requiredPermission: 'manage_users',
      ),
      const _NavItem(
        label: 'Settings', 
        icon: Icons.settings_outlined, 
        route: '/settings',
        requiredPermission: 'manage_users',
      ),
      const _NavItem(
        label: 'Account', 
        icon: Icons.person_outline, 
        route: '/account',
        requiredPermission: null, // All users can access account
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
      return Row(
        children: [
          // Sidebar
          Container(
            width: _collapsed ? _collapsedWidth : _sidebarWidth,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: FlownetColors.charcoalBlack,
              border: Border(
                right: BorderSide(color: FlownetColors.slate, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header with logo and collapse toggle
                Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 24, bottom: 16,),
                  child: Row(
                    children: [
                      const FlownetLogo(
                        showText: false,
                        width: 32,
                        height: 32,
                      ),
                      if (!_collapsed) const SizedBox(width: 8),
                      if (!_collapsed)
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FlownetLogo(showText: true),
                          ),
                        ),
                      IconButton(
                        onPressed: _toggleSidebar,
                        icon: Icon(
                          _collapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          color: FlownetColors.coolGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(
                                item.icon,
                                color: active
                                    ? FlownetColors.crimsonRed
                                    : FlownetColors.coolGray,
                                size: 20,
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
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              if (!routeLocation.startsWith(item.route)) {
                                context.go(item.route);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
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
          ),
        ],
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
                          leading: Icon(
                            item.icon,
                            color: active
                                ? FlownetColors.crimsonRed
                                : FlownetColors.coolGray,
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
      case '/sprint-console':
        return 'Sprint Console';
      case '/settings':
        return 'Settings';
      case '/account':
        return 'Account';
      default:
        return 'Flownet Workspaces';
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final String? requiredPermission;

  const _NavItem({
    required this.label, 
    required this.icon, 
    required this.route,
    this.requiredPermission,
  });
}