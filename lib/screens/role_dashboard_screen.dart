import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../providers/qa_data_provider.dart';

class RoleDashboardScreen extends ConsumerStatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  ConsumerState<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends ConsumerState<RoleDashboardScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();
  late RealtimeService realtimeService;
  bool _isLoadingDashboardDeliverables = false;
  bool _isLoadingDashboardSprints = false;
  bool _isLoadingDashboardApprovals = false;
  bool _isLoadingDashboardProjects = false;
  List<Map<String, dynamic>> _dashboardDeliverables = [];
  List<Map<String, dynamic>> _dashboardSprints = [];
  List<Map<String, dynamic>> _dashboardApprovals = [];
  List<Map<String, dynamic>> _dashboardProjects = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _filteredAuditLogs = [];
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    realtimeService = RealtimeService();
    realtimeService.initialize(authToken: _authService.accessToken);
    _loadCurrentUser();
    _loadUsers();
    _loadDashboardSprints();
    _loadDashboardApprovals();
    _loadDashboardDeliverables();
    _loadDashboardProjects();
    _loadReviewHistoryReports();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    realtimeService.off('user_role_changed', _handleRoleChanged);
    realtimeService.offAll('sprint_created');
    realtimeService.offAll('sprint_updated');
    realtimeService.offAll('deliverable_created');
    realtimeService.offAll('deliverable_updated');
    realtimeService.offAll('approval_created');
    realtimeService.offAll('approval_updated');
    super.dispose();
  }

  void _loadUsers() {}
  Future<void> _loadDashboardSprints() async {
    setState(() => _isLoadingDashboardSprints = true);
    try {
      _dashboardSprints = [];
    } finally {
      if (mounted) setState(() => _isLoadingDashboardSprints = false);
    }
  }
  Future<void> _loadDashboardApprovals() async {
    setState(() => _isLoadingDashboardApprovals = true);
    try {
      _dashboardApprovals = [];
    } finally {
      if (mounted) setState(() => _isLoadingDashboardApprovals = false);
    }
  }
  Future<void> _loadDashboardDeliverables() async {
    setState(() => _isLoadingDashboardDeliverables = true);
    try {
      _dashboardDeliverables = [];
    } finally {
      if (mounted) setState(() => _isLoadingDashboardDeliverables = false);
    }
  }
  Future<void> _loadDashboardProjects() async {
    setState(() => _isLoadingDashboardProjects = true);
    try {
      _dashboardProjects = [];
    } finally {
      if (mounted) setState(() => _isLoadingDashboardProjects = false);
    }
  }
  Future<void> _loadReviewHistoryReports() async {
    _auditLogs = [];
    _filteredAuditLogs = _auditLogs;
  }
  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
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
      case UserRole.developer:
        return _buildDeveloperDashboard();
      case UserRole.projectManager:
        return _buildProjectManagerDashboard();
      case UserRole.scrumMaster:
        return _buildScrumMasterDashboard();
      case UserRole.qaEngineer:
        return _buildQAEngineerDashboard();
      case UserRole.stakeholder:
        return _buildStakeholderDashboard();
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

  Widget _buildQAEngineerDashboard() {
    return Consumer(
      builder: (context, ref, child) {
        final qaNotifier = ref.watch(qaDataProvider.notifier);
        final qaState = ref.watch(qaDataProvider);
        
        if (qaState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (qaState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading QA data'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: qaNotifier.loadQAData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildQAQuickActions(),
              const SizedBox(height: 24),
              _buildTestQueue(qaState.testQueue),
              const SizedBox(height: 24),
              _buildQualityMetrics(qaState.qualityMetrics),
              const SizedBox(height: 24),
              _buildBugReports(qaState.bugReports),
              const SizedBox(height: 24),
              _buildTestCoverage(qaState.testCoverage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQAQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QA Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.bug_report,
                    label: 'Report Bug',
                    onTap: () => context.go('/bug-report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.play_arrow,
                    label: 'Run Tests',
                    onTap: () => context.go('/test-runner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Test Coverage',
                    onTap: () => context.go('/test-coverage'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.timeline,
                    label: 'Quality Metrics',
                    onTap: () => context.go('/quality-metrics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestQueue(List<Map<String, dynamic>> testQueue) {
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
                  'Test Queue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshTestQueue,
                  tooltip: 'Refresh Test Queue',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (testQueue.isEmpty)
              const Center(
                child: Text('No tests in queue'),
              )
            else
              ...testQueue.take(3).map((test) => Column(
                children: [
                  _buildTestQueueItem(
                    test['title'] ?? 'Untitled Test',
                    '${test['priority'] ?? 'Unknown'} Priority',
                    test['status'] ?? 'Unknown',
                    _getTestIcon(test['title'] ?? ''),
                  ),
                  const SizedBox(height: 12),
                ],
              ),),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/test-queue'),
              child: const Text('View Full Test Queue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestQueueItem(String title, String priority, String status, IconData icon) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: _currentUser!.roleColor),
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
                  priority,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshTestQueue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing test queue...')),
    );
  }

  IconData _getTestIcon(String title) {
    if (title.toLowerCase().contains('login') || title.toLowerCase().contains('auth')) {
      return Icons.security;
    } else if (title.toLowerCase().contains('payment')) {
      return Icons.payment;
    } else if (title.toLowerCase().contains('mobile')) {
      return Icons.phone_android;
    } else if (title.toLowerCase().contains('ui')) {
      return Icons.palette;
    } else if (title.toLowerCase().contains('api')) {
      return Icons.api;
    } else {
      return Icons.play_arrow;
    }
  }

  Widget _buildQualityMetrics(Map<String, dynamic> qualityMetrics) {
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
                  'Quality Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshQualityMetrics,
                  tooltip: 'Refresh Quality Metrics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Test Coverage',
                  qualityMetrics['testCoverage'] ?? 'N/A',
                  Icons.analytics,
                  Colors.green,
                ),),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Bugs Found',
                  qualityMetrics['bugsFound']?.toString() ?? 'N/A',
                  Icons.bug_report,
                  Colors.red,
                ),),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Pass Rate',
                  qualityMetrics['passRate'] ?? 'N/A',
                  Icons.check_circle,
                  Colors.green,
                ),),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Avg. Fix Time',
                  qualityMetrics['avgFixTime'] ?? 'N/A',
                  Icons.access_time,
                  Colors.orange,
                ),),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/quality-metrics'),
              child: const Text('View Detailed Metrics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  void _refreshQualityMetrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing quality metrics...')),
    );
  }

  Widget _buildBugReports(List<Map<String, dynamic>> bugReports) {
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
                  'Bug Reports',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshBugReports,
                  tooltip: 'Refresh Bug Reports',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bugReports.isEmpty)
              const Center(
                child: Text('No bug reports'),
              )
            else
              ...bugReports.take(3).map((bug) => Column(
                children: [
                  _buildBugReportItem(
                    bug['title'] ?? 'Untitled Bug',
                    bug['priority'] ?? 'Unknown',
                    bug['status'] ?? 'Unknown',
                    Icons.bug_report,
                    _getBugColor(bug['priority'] ?? ''),
                  ),
                  const SizedBox(height: 12),
                ],
              ),),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/bug-reports'),
              child: const Text('View All Bug Reports'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugReportItem(String title, String priority, String status, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priority == 'High' ? Colors.red : 
                               priority == 'Medium' ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'Open' ? Colors.red : 
                               status == 'In Progress' ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshBugReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing bug reports...')),
    );
  }

  Color _getBugColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTestCoverage(Map<String, dynamic> testCoverage) {
    final overall = double.tryParse((testCoverage['overall'] ?? '0').replaceAll('%', '')) ?? 0;
    final goal = double.tryParse((testCoverage['goal'] ?? '95').replaceAll('%', '')) ?? 95;
    
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
                  'Test Coverage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshTestCoverage,
                  tooltip: 'Refresh Test Coverage',
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: overall / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                overall >= goal ? Colors.green : 
                overall >= goal * 0.8 ? Colors.orange : Colors.red,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${overall.toStringAsFixed(0)}% Coverage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: overall >= goal ? Colors.green : 
                               overall >= goal * 0.8 ? Colors.orange : Colors.red,
                      ),
                ),
                Text(
                  'Goal: ${goal.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCoverageMetric('Unit Tests', testCoverage['unit'] ?? 'N/A', Colors.blue),
                _buildCoverageMetric('Integration', testCoverage['integration'] ?? 'N/A', Colors.orange),
                _buildCoverageMetric('E2E Tests', testCoverage['e2e'] ?? 'N/A', Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/test-coverage'),
              child: const Text('View Detailed Coverage Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageMetric(String type, String percentage, Color color) {
    return Column(
      children: [
        Text(
          type,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  void _refreshTestCoverage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing test coverage...')),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.folder,
                    label: 'Create Project',
                    onTap: _showCreateProjectDialog,
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
            if (_isLoadingDashboardDeliverables)
              const Center(child: CircularProgressIndicator())
            else ...[
              Builder(
                builder: (context) {
                  final items = _dashboardDeliverables.take(3).toList();
                  if (items.isEmpty) {
                    return Text(
                      'No deliverables found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    );
                  }
                  return Column(
                    children: [
                      for (int i=0;i<items.length;i++) ...[
                        _buildDeliverableItem(
                          title: (items[i]['title'] ?? 'Untitled').toString(),
                          status: (items[i]['status'] ?? 'draft').toString(),
                          progress: () {
                            final s = (items[i]['status'] ?? '').toString().toLowerCase();
                            if (s.contains('completed') || s == 'done' || s.contains('approved')) return 1.0;
                            if (s.contains('in') && s.contains('progress')) return 0.6;
                            if (s.contains('review') || s.contains('pending')) return 0.8;
                            return 0.3;
                          }(),
                          dueDate: _parseDate(items[i]['due_date']) ?? _parseDate(items[i]['dueDate']) ?? DateTime.now(),
                        ),
                        if (i < items.length-1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
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
            Builder(
              builder: (context) {
                final items = (_filteredAuditLogs.isNotEmpty ? _filteredAuditLogs : _auditLogs).take(3).toList();
                if (items.isEmpty) {
                  return Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  );
                }
                IconData iconForAction(String a) {
                  final s = a.toLowerCase();
                  if (s.contains('approve')) return Icons.check_circle;
                  if (s.contains('create') || s.contains('add')) return Icons.add;
                  if (s.contains('update') || s.contains('edit')) return Icons.edit;
                  if (s.contains('delete') || s.contains('remove')) return Icons.delete;
                  return Icons.event_note;
                }
                return Column(
                  children: [
                    for (int i=0;i<items.length;i++) ...[
                      _buildActivityItem(
                        icon: iconForAction((items[i]['action'] ?? '').toString()),
                        title: (items[i]['action'] ?? 'Activity').toString(),
                        subtitle: (items[i]['entity_name'] ?? items[i]['entity_type'] ?? '').toString(),
                        time: _relativeTime(items[i]['created_at']?.toString()),
                      ),
                      if (i < items.length-1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
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
  Widget _buildPendingReviews() => _buildPlaceholderCard('Pending Reviews');
  Widget _buildReviewMetrics() => _buildPlaceholderCard('Review Metrics');
  Widget _buildRecentSubmissions() => _buildPlaceholderCard('Recent Submissions');
  Widget _buildReviewHistory() => _buildPlaceholderCard('Review History');

  Widget _buildSprintOverview() {
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
                  'Sprint Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_isLoadingDashboardSprints)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Days Remaining',
                  _computeDaysRemaining(),
                  Icons.calendar_today,
                  Colors.orange,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Points Burned',
                  _computePointsBurned(),
                  Icons.local_fire_department,
                  Colors.red,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Avg Daily Burn',
                  _computeAvgDailyBurn(),
                  Icons.speed,
                  Colors.blue,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals() {
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
                  'Pending Approvals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_isLoadingDashboardApprovals)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Items: ${_dashboardApprovals.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformance() {
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
                  'Team Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_isLoadingDashboardProjects)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Projects: ${_dashboardProjects.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
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
      case UserRole.developer:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/deliverable-setup'),
          icon: const Icon(Icons.code),
          label: const Text('New Feature'),
        );
      case UserRole.projectManager:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/sprint-console'),
          icon: const Icon(Icons.work),
          label: const Text('Manage Project'),
        );
      case UserRole.scrumMaster:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/sprint-console'),
          icon: const Icon(Icons.group_work),
          label: const Text('Manage Sprint'),
        );
      case UserRole.qaEngineer:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/deliverable-setup'),
          icon: const Icon(Icons.bug_report),
          label: const Text('New Test'),
        );
      case UserRole.stakeholder:
        return FloatingActionButton.extended(
          onPressed: () => context.go('/repository'),
          icon: const Icon(Icons.business),
          label: const Text('View Progress'),
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

  void _showCreateProjectDialog() {
    _createNewProject();
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

  // New role-specific dashboard methods
  Widget _buildDeveloperDashboard() {
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

  Widget _buildProjectManagerDashboard() {
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

  Widget _buildScrumMasterDashboard() {
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

  void _createNewProject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project creation is not implemented yet')),
    );
  }

  Widget _buildStakeholderDashboard() {
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

  void _setupRealtimeListeners() {
    realtimeService.on('user_role_changed', _handleRoleChanged);
    realtimeService.on('audit_log_created', _handleAuditLogCreated);
    realtimeService.on('audit_log_deleted', _handleAuditLogDeleted);
    realtimeService.on('audit_log_cleared', _handleAuditLogCleared);
    realtimeService.on('sprint_created', (_) => _loadDashboardSprints());
    realtimeService.on('sprint_updated', (_) => _loadDashboardSprints());
    realtimeService.on('deliverable_created', (_) { _loadDashboardApprovals(); _loadDashboardDeliverables(); });
    realtimeService.on('deliverable_updated', (_) { _loadDashboardApprovals(); _loadDashboardDeliverables(); });
    realtimeService.on('approval_created', (_) => _loadDashboardApprovals());
    realtimeService.on('approval_updated', (_) => _loadDashboardApprovals());
  }

  void _handleRoleChanged(dynamic data) {
    // When a user's role changes, reload the current user and users list
    // to ensure the dashboard reflects the updated role
    if (mounted) {
      _loadCurrentUser();
      _loadUsers();
    }
  }

  void _handleAuditLogCreated(dynamic data) {
    try {
      final Map<String, dynamic> log = Map<String, dynamic>.from(data is Map ? data : {});
      if (log.isEmpty) return;
      setState(() {
        _auditLogs.insert(0, log);
        _filteredAuditLogs = _auditLogs;
      });
    } catch (_) {}
  }

  void _handleAuditLogDeleted(dynamic data) {
    try {
      final String id = (data is Map && data['id'] != null) ? data['id'].toString() : '';
      if (id.isEmpty) return;
      setState(() {
        _auditLogs.removeWhere((log) => (log['id']?.toString() ?? '') == id);
        _filteredAuditLogs = _auditLogs;
      });
    } catch (_) {}
  }

  void _handleAuditLogCleared(dynamic data) {
    setState(() {
      _auditLogs.clear();
      _filteredAuditLogs = _auditLogs;
    });
  }
  Map<String, dynamic>? _selectCurrentSprint() {
    if (_dashboardSprints.isEmpty) return null;
    final inProgress = _dashboardSprints.where((s) {
      final status = (s['status'] ?? s['state'] ?? '').toString().toLowerCase();
      return status == 'in_progress' || status == 'active';
    }).toList();
    if (inProgress.isNotEmpty) return inProgress.first;
    return _dashboardSprints.last;
  }

  String _computeDaysRemaining() {
    final s = _selectCurrentSprint();
    if (s == null) return '0';
    final endStr = s['end_date'] ?? s['endDate'];
    try {
      final end = DateTime.parse(endStr.toString());
      final days = end.difference(DateTime.now()).inDays;
      return days > 0 ? days.toString() : '0';
    } catch (_) {
      return '0';
    }
  }

  String _computePointsBurned() {
    final s = _selectCurrentSprint();
    final completed = _parseInt(s?['completed_points']) ?? _parseInt(s?['completedPoints']) ?? 0;
    return completed.toString();
  }

  String _computeAvgDailyBurn() {
    final s = _selectCurrentSprint();
    if (s == null) return '0';
    final startStr = s['start_date'] ?? s['startDate'];
    final completed = _parseInt(s['completed_points']) ?? _parseInt(s['completedPoints']) ?? 0;
    try {
      final start = DateTime.parse(startStr.toString());
      final days = DateTime.now().difference(start).inDays;
      final avg = days > 0 ? completed / days : completed.toDouble();
      return avg.toStringAsFixed(1);
    } catch (_) {
      return completed.toString();
    }
  }
}

// Extension for number formatting with suffixes (K, M, etc.)
extension NumberFormatting on int {
  String formatWithSuffix() {
    if (this < 1000) return toString();
    
    if (this < 1000000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    
    return '${(this / 1000000).toStringAsFixed(1)}M';
  }
}

class SprintOverviewDetailPage extends StatelessWidget {
  final Map<String, dynamic>? sprint;
  const SprintOverviewDetailPage({super.key, required this.sprint});

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = _parseInt(sprint?['planned_points']) ?? _parseInt(sprint?['committed_points']) ?? _parseInt(sprint?['committedPoints']) ?? 0;
    final completed = _parseInt(sprint?['completed_points']) ?? _parseInt(sprint?['completedPoints']) ?? 0;
    final start = _parseDate(sprint?['start_date'] ?? sprint?['startDate']);
    final end = _parseDate(sprint?['end_date'] ?? sprint?['endDate']);
    final totalDays = (start != null && end != null) ? (end.difference(start).inDays + 1).clamp(1, 60) : 8;
    final todayIndex = (start != null) ? DateTime.now().difference(start).inDays.clamp(0, totalDays - 1) : totalDays - 1;
    final idealPerDay = planned > 0 ? planned / totalDays : 0.0;
    final remainingNow = (planned - completed).clamp(0, planned);
    final burnDownData = List.generate(totalDays, (i) {
      final ideal = (planned - idealPerDay * i).clamp(0.0, planned.toDouble());
      double actualRemaining;
      if (i <= todayIndex && completed > 0 && todayIndex > 0) {
        final completedUpToDay = completed * (i / todayIndex);
        actualRemaining = (planned - completedUpToDay).clamp(0.0, planned.toDouble());
      } else {
        actualRemaining = remainingNow.toDouble();
      }
      return {
        'day': 'Day ${i + 1}',
        'remaining': actualRemaining,
        'ideal': ideal,
      };
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Sprint Overview: ${sprint?['name'] ?? 'Sprint'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _infoTile('Committed', '$planned pts', Icons.assignment, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _infoTile('Completed', '$completed pts', Icons.check_circle, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _infoTile('Progress', planned > 0 ? '${((completed / planned) * 100).toStringAsFixed(0)}%' : '0%', Icons.timeline, Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Burn-down Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < burnDownData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(burnDownData[index]['day'].toString(), style: const TextStyle(fontSize: 10)),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: burnDownData.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), (entry.value['remaining'] as num).toDouble())).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                              dotData: const FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: burnDownData.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), (entry.value['ideal'] as num).toDouble())).toList(),
                              isCurved: false,
                              color: Colors.grey,
                              barWidth: 2,
                              belowBarData: BarAreaData(show: false),
                              dotData: const FlDotData(show: false),
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
