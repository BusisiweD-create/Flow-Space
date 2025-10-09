// ignore_for_file: use_super_parameters, deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool) onToggle;
  final String currentRoute;

  const Sidebar({
    Key? key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final List<SidebarItem> _sidebarItems = [
    SidebarItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      route: '/dashboard',
      tooltip: 'Main Dashboard',
    ),
    SidebarItem(
      title: 'Deliverables',
      icon: Icons.task,
      route: '/deliverable-setup',
      tooltip: 'Manage Deliverables',
    ),
    SidebarItem(
      title: 'Sprints',
      icon: Icons.timeline,
      route: '/sprint-console',
      tooltip: 'Sprint Console',
    ),
    SidebarItem(
      title: 'Sign-off Builder',
      icon: Icons.description,
      route: '/signoff-builder',
      tooltip: 'Build Sign-off Reports',
    ),
    SidebarItem(
      title: 'Client Review',
      icon: Icons.visibility,
      route: '/client-review',
      tooltip: 'Client Review Dashboard',
    ),
    SidebarItem(
      title: 'Audit Trail',
      icon: Icons.history,
      route: '/audit-trail',
      tooltip: 'Audit Trail Logs',
    ),
    SidebarItem(
      title: 'Repository',
      icon: Icons.storage,
      route: '/repository',
      tooltip: 'Signed Reports Repository',
    ),
    SidebarItem(
      title: 'Profile',
      icon: Icons.person,
      route: '/profile',
      tooltip: 'User Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(width: 1, color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          // Header with toggle button
          _buildHeader(),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _sidebarItems.map((item) => _buildNavItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCollapsed)
            const Row(
              children: [
                Icon(Icons.dashboard, size: 24),
                SizedBox(width: 12),
                Text(
                  'Khonology',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              widget.isCollapsed ? Icons.menu_open : Icons.menu,
              size: 20,
            ),
            onPressed: () => widget.onToggle(!widget.isCollapsed),
            tooltip: widget.isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item) {
    final isActive = widget.currentRoute == item.route;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: item.tooltip,
      preferBelow: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: ListTile(
          leading: Icon(
            item.icon,
            color: isActive ? colorScheme.primary : colorScheme.onSurface,
            size: 20,
          ),
          title: !widget.isCollapsed
              ? Text(
                  item.title,
                  style: TextStyle(
                    color: isActive ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : null,
          minLeadingWidth: 0,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 16 : 12,
          ),
          onTap: () {
            if (widget.currentRoute != item.route) {
              context.go(item.route);
            }
          },
        ),
      ),
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  final String route;
  final String tooltip;

  SidebarItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.tooltip,
  });
}