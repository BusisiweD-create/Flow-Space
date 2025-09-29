import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_screen.dart';
import 'deliverable_setup_screen.dart';
import 'sprint_console_screen.dart';
import 'approvals_screen.dart';
import 'repository_screen.dart';
import 'notifications_screen.dart';

// Provider for sidebar state
final sidebarStateProvider = StateNotifierProvider<SidebarStateNotifier, bool>((ref) {
  return SidebarStateNotifier();
});

class SidebarStateNotifier extends StateNotifier<bool> {
  SidebarStateNotifier() : super(false); // false = expanded, true = collapsed

  void toggle() {
    state = !state;
  }
}

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

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<NavigationItem> _navigationItems = [
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

  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarStateProvider);
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 80 : 250,
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
                        if (!isCollapsed) ...[
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
                          icon: Icon(isCollapsed ? Icons.menu : Icons.close),
                          onPressed: () => ref.read(sidebarStateProvider.notifier).toggle(),
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
                            title: isCollapsed ? null : Text(
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
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const DeliverableSetupScreen();
      case 2:
        return const SprintConsoleScreen();
      case 3:
        return const ApprovalsScreen();
      case 4:
        return const RepositoryScreen();
      case 5:
        return const NotificationsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
