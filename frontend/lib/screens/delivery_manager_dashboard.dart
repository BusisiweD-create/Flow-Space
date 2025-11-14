import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sprint.dart';
import '../models/user.dart';
import '../models/deliverable.dart';
import '../providers/client_approval_provider.dart';

class DeliveryManagerDashboard extends ConsumerStatefulWidget {
  const DeliveryManagerDashboard({super.key});

  @override
  ConsumerState<DeliveryManagerDashboard> createState() => _DeliveryManagerDashboardState();
}

class _DeliveryManagerDashboardState extends ConsumerState<DeliveryManagerDashboard> {
  List<Sprint> _sprints = [];
  List<User> _teamMembers = [];
  List<Deliverable> _recentDeliverables = [];
  int _pendingApprovalsCount = 0;
  int _overdueApprovalsCount = 0;
  int _approvalsNeedingReminderCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load active sprints
      final sprints = await ApiService.getSprints();
      final activeSprints = sprints.where((sprint) => sprint.isActive).toList();
      
      // Load team members
      final teamMembers = await ApiService.getUsers();
      
      // Load recent deliverables
      final deliverables = await ApiService.getDeliverables();
      final recentDeliverables = deliverables.take(5).toList();
      
      // Load client approval metrics
      final clientApprovalNotifier = ref.read(clientApprovalProvider.notifier);
      await clientApprovalNotifier.loadApprovalRequests();
      final pendingApprovals = clientApprovalNotifier.getPendingApprovals();
      final overdueApprovals = clientApprovalNotifier.getOverdueApprovals();
      final approvalsNeedingReminder = clientApprovalNotifier.getApprovalsNeedingReminder();
      
      setState(() {
        _sprints = activeSprints;
        _teamMembers = teamMembers;
        _recentDeliverables = recentDeliverables;
        _pendingApprovalsCount = pendingApprovals.length;
        _overdueApprovalsCount = overdueApprovals.length;
        _approvalsNeedingReminderCount = approvalsNeedingReminder.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: $e')),
      );
    }
  }

  void _navigateToTeamManagement() {
    Navigator.pushNamed(context, '/user-management');
  }

  void _navigateToSprintConsole() {
    Navigator.pushNamed(context, '/sprint-console');
  }

  void _navigateToDeliverableReview() {
    Navigator.pushNamed(context, '/deliverable-review');
  }

  void _navigateToReports() {
    Navigator.pushNamed(context, '/reports');
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Manager Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your team, monitor sprints, and oversee project delivery',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard('Team Members', _teamMembers.length.toString(), Icons.people),
                _buildMetricCard('Active Sprints', _sprints.length.toString(), Icons.directions_run),
                _buildMetricCard('Recent Deliverables', _recentDeliverables.length.toString(), Icons.assignment_turned_in),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientApprovalMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Approval Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard('Pending Approvals', _pendingApprovalsCount.toString(), Icons.pending_actions),
                _buildMetricCard('Overdue Approvals', _overdueApprovalsCount.toString(), Icons.warning),
                _buildMetricCard('Need Reminder', _approvalsNeedingReminderCount.toString(), Icons.notifications_active),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton('Team Management', Icons.people, _navigateToTeamManagement),
                _buildActionButton('Sprint Console', Icons.directions_run, _navigateToSprintConsole),
                _buildActionButton('Review Deliverables', Icons.assignment, _navigateToDeliverableReview),
                _buildActionButton('Generate Reports', Icons.analytics, _navigateToReports),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildRecentDeliverables() {
    if (_recentDeliverables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Deliverables',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._recentDeliverables.map((deliverable) => ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text(deliverable.title),
                  subtitle: Text('Status: ${deliverable.statusDisplayName}'),
                ),),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 16),
            _buildTeamMetrics(),
            const SizedBox(height: 16),
            _buildClientApprovalMetrics(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentDeliverables(),
          ],
        ),
      ),
    );
  }
}