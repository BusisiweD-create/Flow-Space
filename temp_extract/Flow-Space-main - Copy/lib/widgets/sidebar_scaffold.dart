import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        route: '/dashboard',),
    _NavItem(
        label: 'Sprints', icon: Icons.timer_outlined, route: '/sprint-console',),
    _NavItem(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        route: '/notifications',),
    _NavItem(
        label: 'Approvals',
        icon: Icons.check_box_outlined,
        route: '/approvals',),
    _NavItem(
        label: 'Repository', icon: Icons.folder_outlined, route: '/repository',),
    _NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        route: '/settings',), // optional
    _NavItem(
        label: 'Account',
        icon: Icons.person_outline,
        route: '/account',), // optional
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
            appBar: AppBar(
              title: const Text('Flow Space'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.apps)),
                      title: const Text('Flow Space'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final active = index == _currentIndex(routeLocation);
                          return ListTile(
                            leading: Icon(item.icon,
                                color: active
                                    ? Theme.of(context).colorScheme.primary
                                    : null,),
                            title: Text(item.label),
                            selected: active,
                            onTap: () {
                              Navigator.pop(context);
                              if (!routeLocation.startsWith(item.route)) {
                                context.go(item.route);
                              }
                            },
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
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _collapsed ? 72 : 260,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header with collapse toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12,),
                        child: Row(
                          children: [
                            const CircleAvatar(
                                radius: 16, child: Icon(Icons.apps, size: 18),),
                            if (!_collapsed) const SizedBox(width: 8),
                            if (!_collapsed)
                              Text(
                                'Flow Space',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            const Spacer(),
                            IconButton(
                              tooltip: _collapsed ? 'Expand' : 'Collapse',
                              onPressed: () async {
                                setState(() => _collapsed = !_collapsed);
                                await _persistCollapsed();
                              },
                              icon: Icon(_collapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: NavigationRail(
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
                                  icon: Icon(e.icon),
                                  selectedIcon: Icon(
                                    e.icon,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  label: Text(e.label),
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
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(
      {required this.label, required this.icon, required this.route,});
}
