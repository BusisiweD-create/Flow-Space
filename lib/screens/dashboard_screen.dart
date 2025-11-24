import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../services/backend_api_service.dart';
import '../widgets/deliverable_card.dart';
import '../widgets/metrics_card.dart';
import '../widgets/sprint_performance_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dashboard metrics
  double? _avgSignoffDays;
  bool _isLoadingDashboard = false;
  String? _dashboardError;

  // Sample data for demonstration
  final List<Deliverable> deliverables = [
    Deliverable(
      id: '1',
      title: 'User Authentication System',
      description: 'Complete user login, registration, and role-based access control',
      status: DeliverableStatus.submitted,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      sprintIds: ['1', '2'],
      definitionOfDone: [
        'All unit tests pass',
        'Code review completed',
        'Security audit passed',
        'Documentation updated',
      ],
    ),
    Deliverable(
      id: '2',
      title: 'Payment Integration',
      description: 'Stripe payment gateway integration with subscription management',
      status: DeliverableStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      sprintIds: ['3'],
      definitionOfDone: [
        'Payment flow tested',
        'PCI compliance verified',
        'Error handling implemented',
        'User documentation created',
      ],
    ),
    Deliverable(
      id: '3',
      title: 'Mobile App Release',
      description: 'iOS and Android app store deployment',
      status: DeliverableStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      sprintIds: ['4', '5'],
      definitionOfDone: [
        'App store approval received',
        'Performance testing completed',
        'User acceptance testing passed',
        'Release notes published',
      ],
    ),
  ];

  final List<Sprint> sprints = [
    Sprint(
      id: '1',
      name: 'Sprint 1 - Auth Foundation',
      startDate: DateTime.now().subtract(const Duration(days: 14)),
      endDate: DateTime.now().subtract(const Duration(days: 7)),
      committedPoints: 21,
      completedPoints: 18,
      velocity: 18,
      testPassRate: 95.5,
      defectCount: 3,
    ),
    Sprint(
      id: '2',
      name: 'Sprint 2 - Auth Enhancement',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
      committedPoints: 19,
      completedPoints: 19,
      velocity: 19,
      testPassRate: 98.2,
      defectCount: 1,
    ),
    Sprint(
      id: '3',
      name: 'Sprint 3 - Payment Integration',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      committedPoints: 25,
      completedPoints: 12,
      velocity: 0, // In progress
      testPassRate: 92.1,
      defectCount: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
  }

  Future<void> _loadDashboardMetrics() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final api = BackendApiService();
      await api.initialize();
      final response = await api.getDashboardData();

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        final stats = data['statistics'] ?? {};
        final rawAvg = stats['avg_signoff_days'];

        setState(() {
          if (rawAvg == null) {
            _avgSignoffDays = null;
          } else if (rawAvg is num) {
            _avgSignoffDays = rawAvg.toDouble();
          } else {
            _avgSignoffDays = double.tryParse(rawAvg.toString());
          }
        });
      } else {
        setState(() {
          _dashboardError = response.error ?? 'Failed to load dashboard data';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardError = 'Error loading dashboard: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDashboard = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow-Space Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => context.go('/deliverable-setup'),
            tooltip: 'Create Deliverable',
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () => context.go('/sprint-console'),
            tooltip: 'Sprint Console',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
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
            child: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: _isLoadingDashboard
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  if (_dashboardError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dashboardError!,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Key Metrics Row
                  _buildMetricsRow(),
                  const SizedBox(height: 24),

                  // Sprint Performance Chart
                  _buildSprintPerformanceSection(),
                  const SizedBox(height: 24),

                  // Deliverables Section
                  _buildDeliverablesSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateDeliverableDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Deliverable'),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.dashboard,
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
                    'Welcome to Khonology',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deliverable & Sprint Sign-Off Hub',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track deliverables, monitor sprint performance, and manage client approvals',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final totalDeliverables = deliverables.length;
    final approvedDeliverables = deliverables.where((d) => d.status == DeliverableStatus.approved).length;
    final pendingDeliverables = deliverables.where((d) => d.status == DeliverableStatus.submitted).length;

    return Row(
      children: [
        Expanded(
          child: MetricsCard(
            title: 'Total Deliverables',
            value: totalDeliverables.toString(),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Approved',
            value: approvedDeliverables.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Pending Review',
            value: pendingDeliverables.toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Avg. Sign-off',
            value: _avgSignoffDays == null
                ? '--'
                : '${_avgSignoffDays!.toStringAsFixed(1)}d',
            icon: Icons.schedule,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSprintPerformanceSection() {
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
                  'Sprint Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showSprintManagementDialog();
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text('View Details'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.analytics),
                      onPressed: () {
                        context.go('/performance-dashboard');
                      },
                      tooltip: 'Performance Dashboard',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SprintPerformanceChart(sprints: sprints.map((sprint) {
                return {
                  'id': sprint.id,
                  'name': sprint.name,
                  'start_date': sprint.startDate.toIso8601String(),
                  'end_date': sprint.endDate.toIso8601String(),
                  'planned_points': sprint.committedPoints,
                  'completed_points': sprint.completedPoints,
                  'status': 'completed',
                };
              }).toList(),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverablesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Deliverables',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAllDeliverablesDialog();
              },
              icon: const Icon(Icons.list),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...deliverables.map((deliverable) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DeliverableCard(
                deliverable: deliverable,
                onTap: () {
                  _showDeliverableDetailsDialog(deliverable);
                },
              ),
            ),),
      ],
    );
  }

  void _showCreateDeliverableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deliverable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the type of deliverable setup:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Quick Setup'),
              subtitle: const Text('Basic deliverable creation'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/deliverable-setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering),
              title: const Text('Enhanced Setup'),
              subtitle: const Text('Full DoD, evidence, and readiness check'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/enhanced-deliverable-setup');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications at this time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  void _showSprintManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sprint Management'),
        content: const Text('Sprint management features will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAllDeliverablesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Deliverables'),
        content: const Text('Complete deliverables list will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeliverableDetailsDialog(Deliverable deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deliverable.title),
        content: Text(deliverable.description),
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
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
