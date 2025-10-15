import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_screen.dart';
import 'deliverable_setup_screen.dart';
import 'sprint_console_screen.dart';
import 'approvals_screen.dart';
import 'repository_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isCollapsed = false;
  
  List<NavigationItem> get _navigationItems {
    final authService = AuthService();
    final isAdmin = authService.isSystemAdmin;
    
    final items = [
      NavigationItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      NavigationItem(
        icon: Icons.assignment,
        label: 'Deliverables',
        route: '/deliverable-setup',
      ),
      NavigationItem(
        icon: Icons.timeline,
        label: 'Sprints',
        route: '/sprint-console',
      ),
      NavigationItem(
        icon: Icons.approval,
        label: 'Approvals',
        route: '/approvals',
      ),
      NavigationItem(
        icon: Icons.folder,
        label: 'Repository',
        route: '/repository',
      ),
      NavigationItem(
        icon: Icons.notifications,
        label: 'Notifications',
        route: '/notifications',
      ),
    ];
    
    // Add settings option for admin users
    if (isAdmin) {
      items.add(
        NavigationItem(
          icon: Icons.settings,
          label: 'Settings',
          route: '/settings',
        ),
      );
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCollapsed ? 80 : 250,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 60,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (!_isCollapsed) ...[
                          const Icon(Icons.work, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Khonology',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: Icon(_isCollapsed ? Icons.menu : Icons.close),
                          onPressed: () {
                            setState(() {
                              _isCollapsed = !_isCollapsed;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        final isSelected = _currentIndex == index;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: ListTile(
                            leading: Icon(
                              item.icon,
                              color: isSelected ? Colors.blue : Colors.grey[600],
                            ),
                            title: _isCollapsed ? null : Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? Colors.blue : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                              });
                              context.go(item.route);
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
          // Main Content
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // Get the current navigation item to determine which screen to show
    if (_currentIndex >= 0 && _currentIndex < _navigationItems.length) {
      final item = _navigationItems[_currentIndex];
      
      switch (item.route) {
        case '/dashboard':
          return const DashboardScreen();
        case '/deliverable-setup':
          return const DeliverableSetupScreen();
        case '/sprint-console':
          return const SprintConsoleScreen();
        case '/approvals':
          return const ApprovalsScreen();
        case '/repository':
          return const RepositoryScreen();
        case '/notifications':
          return const NotificationsScreen();
        case '/settings':
          return const SettingsScreen();
        default:
          return const DashboardScreen();
      }
    }
    
    return const DashboardScreen();
  }
}
