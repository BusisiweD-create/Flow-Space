import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/flownet_theme.dart';
import 'flownet_logo.dart';

class SidebarScaffold extends StatefulWidget {
  final Widget child;

  const SidebarScaffold({super.key, required this.child});

  @override
  State<SidebarScaffold> createState() => _SidebarScaffoldState();
}

class _SidebarScaffoldState extends State<SidebarScaffold> {
  static const _prefsKey = '__sidebar_collapsed';
  bool _collapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _items = const <_NavItem>[
    _NavItem(
        label: 'Deliverables',
        icon: Icons.dashboard_outlined,
        route: '/dashboard'),
    _NavItem(
        label: 'Sprints', icon: Icons.timer_outlined, route: '/sprint-console'),
    _NavItem(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        route: '/notifications'),
    _NavItem(
        label: 'Approvals',
        icon: Icons.check_box_outlined,
        route: '/approvals'),
    _NavItem(
        label: 'Repository', icon: Icons.folder_outlined, route: '/repository'),
    _NavItem(
        label: 'Settings', icon: Icons.settings_outlined, route: '/settings'),
    _NavItem(label: 'Account', icon: Icons.person_outline, route: '/account'),
  ];

  @override
  void initState() {
    super.initState();
    _restoreCollapsed();
  }

  Future<void> _restoreCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collapsed = prefs.getBool(_prefsKey) ?? false;
    });
  }

  Future<void> _persistCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _collapsed);
  }

  int _currentIndex(String location) {
    final i = _items.indexWhere((e) => location.startsWith(e.route));
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final routeLocation = GoRouterState.of(context).uri.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        // Mobile: slide-in drawer + app bar with menu
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: FlownetColors.charcoalBlack,
            appBar: AppBar(
              backgroundColor: FlownetColors.charcoalBlack,
              foregroundColor: FlownetColors.pureWhite,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              ),
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
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final active = index == _currentIndex(routeLocation);
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: active
                                  ? FlownetColors.crimsonRed.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: active
                                  ? Border(
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
            body: widget.child,
          );
        }

        // Desktop/tablet: fixed sidebar (NavigationRail)
        return Scaffold(
          backgroundColor: FlownetColors.charcoalBlack,
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _collapsed ? 72 : 260,
                decoration: const BoxDecoration(
                  color: FlownetColors.charcoalBlack,
                  border: Border(
                    right: BorderSide(color: FlownetColors.slate, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header with logo and collapse toggle
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 24, bottom: 16),
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
                              tooltip: _collapsed ? 'Expand' : 'Collapse',
                              onPressed: () async {
                                setState(() => _collapsed = !_collapsed);
                                await _persistCollapsed();
                              },
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
                      Expanded(
                        child: NavigationRail(
                          backgroundColor: FlownetColors.charcoalBlack,
                          extended: !_collapsed,
                          selectedIndex: _currentIndex(routeLocation),
                          onDestinationSelected: (index) {
                            final dest = _items[index];
                            if (!routeLocation.startsWith(dest.route)) {
                              context.go(dest.route);
                            }
                          },
                          labelType: _collapsed
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.none,
                          leading: const SizedBox(height: 8),
                          destinations: _items
                              .map(
                                (e) => NavigationRailDestination(
                                  icon: Icon(
                                    e.icon,
                                    color: FlownetColors.coolGray,
                                  ),
                                  selectedIcon: Icon(
                                    e.icon,
                                    color: FlownetColors.crimsonRed,
                                  ),
                                  label: Text(
                                    e.label,
                                    style: const TextStyle(
                                      color: FlownetColors.pureWhite,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
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
                              horizontal: 16, vertical: 8),
                          decoration: const BoxDecoration(
                            color: FlownetColors.graphiteGray,
                            border: Border(
                              bottom: BorderSide(
                                  color: FlownetColors.slate, width: 1),
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
                                          'Forward navigation coming soon'),
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
        );
      },
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
  const _NavItem(
      {required this.label, required this.icon, required this.route});
}
