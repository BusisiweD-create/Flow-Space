import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import '../services/auth_service.dart';
import 'background_image.dart';

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
        label: 'Epics', 
        icon: Icons.rocket_launch_outlined, 
        route: '/epics',
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
        route: '/approvals',
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
        requiredPermission: null, // Allow all authenticated users (especially client reviewers)
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
        requiredPermission: null, // All authenticated users can access settings
      ),
      const _NavItem(
        label: 'Profile', 
        icon: Icons.person_outline, 
        route: '/profile',
        requiredPermission: null, // All users can access profile
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
    final routeLocation = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundImage(
          child: Row(
            children: [
              // Sidebar with semi-transparent background
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _collapsed ? _collapsedWidth : _sidebarWidth,
                decoration: const BoxDecoration(),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        border: const Border(
                          right: BorderSide(
                            color: Color.fromARGB(51, 255, 255, 255),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header with logo and collapse toggle
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, top: 24, bottom: 16,),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/Icons/Red_Khono_Discs.png',
                                  width: _collapsed ? 28 : 64,
                                  height: _collapsed ? 28 : 64,
                                  fit: BoxFit.contain,
                                ),
                                IconButton(
                                  onPressed: _toggleSidebar,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    _collapsed
                                        ? Icons.chevron_right
                                        : Icons.chevron_left,
                                    color: FlownetColors.coolGray,
                                    size: 20,
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
                              itemExtent: 56, // Fixed height for better performance
                              cacheExtent: 200, // Cache more items for smoother scrolling
                              addAutomaticKeepAlives: true, // Keep state of list items
                              itemBuilder: (context, index) {
                                final item = _navItems[index];
                                final active = routeLocation.startsWith(item.route);
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2,),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? FlownetColors.crimsonRed.withAlpha((0.1 * 255).round())
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            child: _buildLogoutButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Top navigation bar with back/forward buttons
                      if (routeLocation != '/dashboard')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.08 * 255).round()),
                            border: const Border(
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
          ),
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Image.asset(
            'assets/Icons/Red_Khono_Discs.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Image.asset(
                      'assets/Icons/Red_Khono_Discs.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Divider(color: FlownetColors.slate),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemExtent: 56, // Fixed height for better performance
                    cacheExtent: 200, // Cache more items for smoother scrolling
                    addAutomaticKeepAlives: true, // Keep state of list items
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final active = routeLocation.startsWith(item.route);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,),
                        decoration: BoxDecoration(
                          color: active
                              ? FlownetColors.crimsonRed.withAlpha((0.1 * 255).round())
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: FlownetColors.coolGray,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: FlownetColors.pureWhite),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BackgroundImage(
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

  Future<void> _handleLogout(BuildContext ctx) async {
    final router = GoRouter.of(ctx);
    await AuthService().signOut();
    if (!mounted) return;
    router.go('/');
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(
          Icons.logout,
          color: FlownetColors.coolGray,
          size: 20,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: FlownetColors.coolGray,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      ),
    );
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
      case '/profile':
        return 'Profile';
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