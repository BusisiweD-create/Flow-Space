import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Get the current user from AuthService
      final user = _authService.currentUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        debugPrint('✅ Loaded user: ${user.name} (${user.email})');
      } else {
        debugPrint('❌ No user found, redirecting to login');
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading current user: $e');
      // If there's an error, redirect to login
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildRoleSpecificContent(),
      floatingActionButton: _buildRoleSpecificFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('${_currentUser!.roleDisplayName} Dashboard'),
      backgroundColor: _currentUser!.roleColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.go('/notification-center'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettingsDialog(),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            } else if (value == 'profile') {
              _showProfileDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(_currentUser!.roleIcon),
                  const SizedBox(width: 8),
                  const Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              _currentUser!.roleIcon,
              color: _currentUser!.roleColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSpecificContent() {
    switch (_currentUser!.role) {
      case UserRole.teamMember:
        return _buildTeamMemberDashboard();
      case UserRole.deliveryLead:
        return _buildDeliveryLeadDashboard();
      case UserRole.clientReviewer:
        return _buildClientReviewerDashboard();
      case UserRole.systemAdmin:
        return _buildSystemAdminDashboard();
    }
  }

  Widget _buildTeamMemberDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildMyDeliverables(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildDeliveryLeadDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildTeamMetrics(),
          const SizedBox(height: 24),
          _buildSprintOverview(),
          const SizedBox(height: 24),
          _buildPendingReviews(),
          const SizedBox(height: 24),
          _buildTeamPerformance(),
        ],
      ),
    );
  }

  Widget _buildClientReviewerDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildReviewMetrics(),
          const SizedBox(height: 24),
          _buildPendingApprovals(),
          const SizedBox(height: 24),
          _buildRecentSubmissions(),
          const SizedBox(height: 24),
          _buildReviewHistory(),
        ],
      ),
    );
  }

  Widget _buildSystemAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildSystemMetrics(),
          const SizedBox(height: 24),
          _buildUserManagement(),
          const SizedBox(height: 24),
          _buildSystemHealth(),
          const SizedBox(height: 24),
          _buildAuditLogs(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _currentUser!.roleColor,
              child: Icon(
                _currentUser!.roleIcon,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${_currentUser!.name.split(' ').first}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.roleDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_task,
                    label: 'New Deliverable',
                    onTap: () => context.go('/deliverable-setup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.timeline,
                    label: 'Sprint Console',
                    onTap: () => context.go('/sprint-console'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: _currentUser!.roleColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDeliverables() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Deliverables',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/repository'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeliverableItem(
              title: 'User Authentication System',
              status: 'In Progress',
              progress: 0.75,
              dueDate: DateTime.now().add(const Duration(days: 2)),
            ),
            const SizedBox(height: 12),
            _buildDeliverableItem(
              title: 'Payment Integration',
              status: 'Draft',
              progress: 0.25,
              dueDate: DateTime.now().add(const Duration(days: 7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverableItem({
    required String title,
    required String status,
    required double progress,
    required DateTime dueDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_currentUser!.roleColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Due: ${_formatDate(dueDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.check_circle,
              title: 'Deliverable approved',
              subtitle: 'User Authentication System',
              time: '2 hours ago',
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: Icons.edit,
              title: 'Deliverable updated',
              subtitle: 'Payment Integration',
              time: '1 day ago',
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: Icons.add,
              title: 'New deliverable created',
              subtitle: 'Mobile App Release',
              time: '3 days ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _currentUser!.roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _currentUser!.roleColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
        ),
      ],
    );
  }

  // Placeholder methods for other role-specific content
  Widget _buildTeamMetrics() => _buildPlaceholderCard('Team Metrics');
  Widget _buildSprintOverview() => _buildPlaceholderCard('Sprint Overview');
  Widget _buildPendingReviews() => _buildPlaceholderCard('Pending Reviews');
  Widget _buildTeamPerformance() => _buildPlaceholderCard('Team Performance');
  Widget _buildReviewMetrics() => _buildPlaceholderCard('Review Metrics');
  Widget _buildPendingApprovals() => _buildPlaceholderCard('Pending Approvals');
  Widget _buildRecentSubmissions() => _buildPlaceholderCard('Recent Submissions');
  Widget _buildReviewHistory() => _buildPlaceholderCard('Review History');
  Widget _buildSystemMetrics() => _buildPlaceholderCard('System Metrics');
  Widget _buildUserManagement() => _buildPlaceholderCard('User Management');
  Widget _buildSystemHealth() => _buildPlaceholderCard('System Health');
  Widget _buildAuditLogs() => _buildPlaceholderCard('Audit Logs');

  Widget _buildPlaceholderCard(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '$title content will be implemented here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRoleSpecificFAB() {
    switch (_currentUser!.role) {
      case UserRole.teamMember:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/deliverable-setup'),
          icon: const Icon(Icons.add),
          label: const Text('New Deliverable'),
        );
      case UserRole.deliveryLead:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/sprint-console'),
          icon: const Icon(Icons.timeline),
          label: const Text('Manage Sprint'),
        );
      case UserRole.clientReviewer:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/approvals'),
          icon: const Icon(Icons.approval),
          label: const Text('Review Items'),
        );
      case UserRole.systemAdmin:
        return FloatingActionButton.extended(
          onPressed: () => _showAdminMenu(),
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Admin Panel'),
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'pending':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return 'Overdue';
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings panel will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_currentUser!.name} Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_currentUser!.roleIcon, color: _currentUser!.roleColor),
                const SizedBox(width: 8),
                Text(_currentUser!.roleDisplayName),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: ${_currentUser!.email}'),
            const SizedBox(height: 8),
            Text(_currentUser!.roleDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAdminMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Panel'),
        content: const Text('Admin panel features will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              navigator.pop();
              // Sign out the user
              await _authService.signOut();
              if (mounted) {
                router.go('/');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
