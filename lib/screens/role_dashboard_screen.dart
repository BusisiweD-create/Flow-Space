import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/backend_api_service.dart';
import '../services/api_service.dart';

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
  final BackendApiService _backendService = BackendApiService();
  Map<String, dynamic> _systemMetrics = {};
  bool _isLoadingSystemMetrics = false;
  String? _systemMetricsError;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;
  bool _isLoadingAuditLogs = false;
  String? _auditLogsError;

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
    _loadSystemMetrics();
    _loadSystemHealth();
    _setupRealtimeListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentUser();
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

  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });
    try {
      final resp = await _backendService.getUsers(page: 1, limit: 100);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['data'] ?? raw['users'] ?? raw['items'] ?? []) : (raw is List ? raw : []);
        setState(() {
          _users = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        });
      } else {
        setState(() {
          _users = [];
          _usersError = resp.error ?? 'Failed to load users';
        });
      }
    } catch (e) {
      setState(() {
        _usersError = 'Failed to load users';
        _users = [];
      });
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }
  Future<void> _loadDashboardSprints() async {
    setState(() => _isLoadingDashboardSprints = true);
    try {
      final items = await ApiService.getSprints();
      _dashboardSprints = items;
    } finally {
      if (mounted) setState(() => _isLoadingDashboardSprints = false);
    }
  }
  Future<void> _loadDashboardApprovals() async {
    setState(() => _isLoadingDashboardApprovals = true);
    try {
      final resp = await _backendService.getApprovalRequests(status: 'pending', page: 1, limit: 100);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['data'] ?? raw['requests'] ?? raw['items'] ?? []) : (raw is List ? raw : []);
        _dashboardApprovals = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        _dashboardApprovals = [];
      }
    } finally {
      if (mounted) setState(() => _isLoadingDashboardApprovals = false);
    }
  }
  Future<void> _loadDashboardDeliverables() async {
    setState(() => _isLoadingDashboardDeliverables = true);
    try {
      final items = await ApiService.getDeliverables();
      _dashboardDeliverables = items;
    } finally {
      if (mounted) setState(() => _isLoadingDashboardDeliverables = false);
    }
  }
  Future<void> _loadDashboardProjects() async {
    setState(() => _isLoadingDashboardProjects = true);
    try {
      final resp = await _backendService.getProjects(page: 1, limit: 100);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['data'] ?? raw['projects'] ?? raw['items'] ?? []) : (raw is List ? raw : []);
        _dashboardProjects = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        _dashboardProjects = [];
      }
    } finally {
      if (mounted) setState(() => _isLoadingDashboardProjects = false);
    }
  }
  Future<void> _loadReviewHistoryReports() async {
    setState(() {
      _isLoadingAuditLogs = true;
      _auditLogsError = null;
    });
    try {
      final resp = await _backendService.getRealAuditLogs(skip: 0, limit: 50);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['audit_logs'] ?? raw['items'] ?? raw['logs'] ?? raw['data'] ?? []) : (raw is List ? raw : []);
        final list = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        setState(() {
          _auditLogs = list;
          _filteredAuditLogs = _auditLogs;
        });
      } else {
        setState(() {
          _auditLogs = [];
          _filteredAuditLogs = _auditLogs;
          _auditLogsError = resp.error ?? 'Failed to load audit logs';
        });
      }
    } catch (e) {
      setState(() {
        _auditLogsError = 'Failed to load audit logs';
        _auditLogs = [];
        _filteredAuditLogs = _auditLogs;
      });
    } finally {
      if (mounted) setState(() => _isLoadingAuditLogs = false);
    }
  }
  Future<void> _loadSystemMetrics() async {
    setState(() {
      _isLoadingSystemMetrics = true;
      _systemMetricsError = null;
    });
    try {
      final data = await ApiService.getDashboardData();
      setState(() {
        _systemMetrics = data;
        _isLoadingSystemMetrics = false;
      });
    } catch (e) {
      setState(() {
        _systemMetricsError = 'Failed to load system metrics';
        _isLoadingSystemMetrics = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Get the current user from AuthService
      final user = await _authService.getCurrentUser();
      if (user != null && user.isActive) {
        setState(() {
          _currentUser = user;
        });
        debugPrint('✅ Loaded user: ${user.name} (${user.email})');
      } else {
        debugPrint('❌ Inactive or no user found, redirecting to login');
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          final router = GoRouter.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Your account is inactive. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
          await _authService.signOut();
          router.go('/');
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
          _buildReminderQuickActions(),
          const SizedBox(height: 24),
          _buildTeamMetrics(),
          const SizedBox(height: 24),
          _buildSprintOverview(),
          const SizedBox(height: 24),
          _buildProjectsOverview(),
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
          _buildReminderQuickActions(),
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


  Widget _buildReminderQuickActions() {
    final canShow = _currentUser != null && (_currentUser!.isDeliveryLead || _currentUser!.isSystemAdmin);
    if (!canShow) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.notifications_active, 'Approval Reminders', route: '/approvals'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.assignment,
                    label: 'Send Reminder For Report',
                    onTap: _showReminderSelectionDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderSelectionDialog() async {
    try {
      final resp = await _backendService.getSignOffReports(page: 1, limit: 50);
      final raw = resp.data;
      final List<dynamic> items = raw is List
          ? raw
          : (raw is Map ? (raw['data'] ?? raw['reports'] ?? raw['items'] ?? []) : []);

      final reports = items
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      String? selectedReportId = reports.isNotEmpty ? (reports.first['id']?.toString()) : null;
      String recipientRole = 'client_reviewer';

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Send Reminder For Report'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReportId,
                    items: reports.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['id']?.toString(),
                        child: Text(((r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title']) ?? 'Untitled Report').toString()),
                      );
                    }).toList(),
                    onChanged: (value) => selectedReportId = value,
                    decoration: const InputDecoration(
                      labelText: 'Select Report',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: recipientRole,
                    items: const [
                      DropdownMenuItem(value: 'client_reviewer', child: Text('Client Reviewer')),
                      DropdownMenuItem(value: 'delivery_lead', child: Text('Delivery Lead')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => recipientRole = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Recipient Role',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedReportId != null) {
                    _sendReminder(selectedReportId!, recipientRole);
                    context.pop();
                  }
                },
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    }
  }

  void _sendReminder(String reportId, String recipientRole) async {
    try {
      final response = await _backendService.sendReminderForReport(reportId, recipientRole);
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder: ${response.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Widget _buildRoleSpecificFAB() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text('Create Deliverable'),
                    onTap: () {
                      context.go('/deliverable-setup');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('Open Sprint Console'),
                    onTap: () {
                      context.go('/sprint-console');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('User Management'),
                    onTap: () {
                      context.go('/user-management');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Role Management'),
                    onTap: () {
                      context.go('/role-management');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      backgroundColor: _currentUser?.roleColor ?? Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: ListTile(
        leading: Icon(_currentUser?.roleIcon ?? Icons.person),
        title: Text('Welcome, ${_currentUser?.name ?? 'User'}'),
        subtitle: Text('${_currentUser?.roleDisplayName ?? 'Member'} Dashboard'),
      ),
    );
  }

  Widget _buildQuickActions() {
    return const Row(
      children: [
        Expanded(child: Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Quick Action 1')))),
        SizedBox(width: 12),
        Expanded(child: Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Quick Action 2')))),
      ],
    );
  }

  Widget _buildMyDeliverables() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardDeliverables
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.assignment_outlined, 'My Deliverables (${_dashboardDeliverables.length})', route: '/repository'),
                  const SizedBox(height: 8),
                  ..._dashboardDeliverables.take(5).map((d) {
                    final title = d['title'] ?? d['name'] ?? d['deliverableName'] ?? 'Untitled Deliverable';
                    final status = d['status'] ?? d['reviewStatus'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final id = d['id']?.toString() ?? d['uuid']?.toString() ?? '';
                          final route = id.isNotEmpty ? '/report-editor/$id' : '/repository';
                          context.go(route);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_turned_in, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status.toString().isNotEmpty ? '$title • $status' : title)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingAuditLogs
            ? const Center(child: CircularProgressIndicator())
            : (_auditLogsError != null
                ? Text(_auditLogsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.history, 'Recent Activity (${_filteredAuditLogs.length})', route: '/notifications'),
                      const SizedBox(height: 8),
                      ..._filteredAuditLogs.take(5).map((a) {
                        final action = a['action'] ?? a['event'] ?? a['type'] ?? 'Activity';
                        final actor = a['actor'] ?? a['user'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              context.go('/notifications');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(actor.toString().isNotEmpty ? '$action • $actor' : action)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget _buildTeamMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardHeader(Icons.group_outlined, 'Team Metrics', route: '/sprint-console'),
      ),
    );
  }

  Widget _buildSprintOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardSprints
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.flag_outlined, 'Sprint Overview (${_dashboardSprints.length})', route: '/sprint-console'),
                  const SizedBox(height: 8),
                  ..._dashboardSprints.take(5).map((s) {
                    final name = s['name'] ?? s['title'] ?? s['sprintName'] ?? 'Sprint';
                    final status = s['status'] ?? s['state'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final id = s['id']?.toString() ?? s['uuid']?.toString() ?? '';
                          final name = s['name']?.toString() ?? s['title']?.toString() ?? '';
                          final route = id.isNotEmpty 
                              ? '/sprint-board/$id${name.isNotEmpty ? '?name=${Uri.encodeComponent(name)}' : ''}'
                              : '/sprint-console';
                          context.go(route);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status.toString().isNotEmpty ? '$name • $status' : name)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildProjectsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardProjects
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.folder_outlined, 'Projects (${_dashboardProjects.length})', route: '/repository'),
                  const SizedBox(height: 8),
                  ..._dashboardProjects.take(5).map((p) {
                    final name = p['name'] ?? p['title'] ?? p['projectName'] ?? 'Untitled Project';
                    final status = p['status'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final projectKey = p['projectKey']?.toString() ?? p['key']?.toString() ?? p['slug']?.toString() ?? '';
                          final route = projectKey.isNotEmpty ? '/repository/$projectKey' : '/repository';
                          context.go(route);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status.toString().isNotEmpty ? '$name • $status' : name)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingReviews() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardApprovals
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.fact_check_outlined, 'Pending Reviews (${_dashboardApprovals.length})', route: '/approvals'),
                  const SizedBox(height: 8),
                  ..._dashboardApprovals.take(5).map((a) {
                    final title = a['title'] ?? a['requestTitle'] ?? a['deliverableTitle'] ?? 'Approval Request';
                    final requester = a['requester'] ?? a['createdBy'] ?? a['user'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          context.go('/approvals');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(requester.toString().isNotEmpty ? '$title • $requester' : title)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildTeamPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardHeader(Icons.insights_outlined, 'Team Performance', route: '/sprint-console'),
      ),
    );
  }

  Widget _buildReviewMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardHeader(Icons.rate_review_outlined, 'Review Metrics', route: '/report-repository'),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardApprovals
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.rule_folder_outlined, 'Pending Approvals (${_dashboardApprovals.length})', route: '/approval-requests'),
                  const SizedBox(height: 8),
                  ..._dashboardApprovals.take(5).map((a) {
                    final title = a['title'] ?? a['requestTitle'] ?? a['deliverableTitle'] ?? 'Approval Request';
                    final requester = a['requester'] ?? a['createdBy'] ?? a['user'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          context.go('/approval-requests');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(requester.toString().isNotEmpty ? '$title • $requester' : title)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentSubmissions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardHeader(Icons.upload_outlined, 'Recent Submissions', route: '/report-repository'),
      ),
    );
  }

  Widget _buildReviewHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingAuditLogs
            ? const Center(child: CircularProgressIndicator())
            : (_auditLogsError != null
                ? Text(_auditLogsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.rate_review_outlined, 'Review History (${_filteredAuditLogs.length})', route: '/report-repository'),
                      const SizedBox(height: 8),
                      ..._filteredAuditLogs.take(5).map((a) {
                        final action = a['action'] ?? a['event'] ?? a['type'] ?? 'Review';
                        final actor = a['actor'] ?? a['user'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              context.go('/report-repository');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.rate_review_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(actor.toString().isNotEmpty ? '$action • $actor' : action)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget _buildSystemMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingSystemMetrics
            ? const Center(child: CircularProgressIndicator())
            : (_systemMetricsError != null
                ? Text(_systemMetricsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.dashboard_outlined, 'System Metrics (${_systemMetrics.keys.length})', route: '/settings'),
                      const SizedBox(height: 12),
                      if (_systemMetrics.isEmpty)
                        const Text('No metrics available')
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _systemMetrics.entries.take(6).map((e) {
                            final key = e.key.toString();
                            final value = e.value;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_iconForMetricKey(key)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_labelForMetricKey(key), style: Theme.of(context).textTheme.bodyMedium),
                                      Text(_stringValue(value), style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  )),
      ),
    );
  }

  Widget _buildUserManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingUsers
            ? const Center(child: CircularProgressIndicator())
            : (_usersError != null
                ? Text(_usersError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.people_outline, 'User Management (${_users.length})', route: '/role-management'),
                      const SizedBox(height: 8),
                      ..._users.take(5).map((u) {
                        final rawName = (u['name'] ?? u['fullName'] ?? u['full_name'] ?? '').toString();
                        final first = (u['firstName'] ?? u['first_name'] ?? '').toString();
                        final last = (u['lastName'] ?? u['last_name'] ?? '').toString();
                        final username = (u['username'] ?? '').toString();
                        final displayName = rawName.trim().isNotEmpty
                            ? rawName
                            : (('$first $last').trim().isNotEmpty
                                ? [first, last].where((s) => s.trim().isNotEmpty).join(' ')
                                : (username.isNotEmpty ? username : 'User'));
                        final roleRaw = u['roleDisplayName'] ?? u['role'];
                        final roleStr = roleRaw?.toString() ?? '';
                        String roleDisplay = roleStr;
                        try {
                          final match = UserRole.values.firstWhere((r) => r.name == roleStr);
                          roleDisplay = match.displayName;
                        } catch (_) {
                          roleDisplay = roleStr.isNotEmpty ? roleStr : '';
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              context.go('/role-management');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(roleDisplay.isNotEmpty ? '$displayName • $roleDisplay' : displayName)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Map<String, dynamic> _systemHealth = {};
  bool _isLoadingSystemHealth = false;
  String? _systemHealthError;

  Future<void> _loadSystemHealth() async {
    setState(() {
      _isLoadingSystemHealth = true;
      _systemHealthError = null;
    });
    try {
      final resp = await _backendService.getSystemHealth();
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        Map<String, dynamic> map;
        if (raw is Map<String, dynamic>) {
          map = raw;
        } else if (raw is Map) {
          map = Map<String, dynamic>.from(raw);
        } else {
          map = {};
        }
        setState(() {
          _systemHealth = map;
        });
      } else {
        setState(() {
          _systemHealthError = resp.error ?? 'Failed to load system health';
          _systemHealth = {};
        });
      }
    } catch (e) {
      setState(() {
        _systemHealthError = 'Failed to load system health';
        _systemHealth = {};
      });
    } finally {
      if (mounted) setState(() => _isLoadingSystemHealth = false);
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('healthy') || s.contains('ok') || s.contains('up')) return Colors.green;
    if (s.contains('warn') || s.contains('degrade')) return Colors.orange;
    if (s.contains('critical') || s.contains('down') || s.contains('error') || s.contains('fail')) return Colors.red;
    return Colors.grey;
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: 8),
                Text('System Health', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSystemHealth,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingSystemHealth)
              const Center(child: CircularProgressIndicator())
            else if (_systemHealthError != null)
              Text(_systemHealthError!)
            else if (_systemHealth.isEmpty)
              const Text('No health data available')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _systemHealth.entries.take(8))
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: _statusColor(entry.value is Map && (entry.value['status'] ?? '').toString().isNotEmpty ? entry.value['status'].toString() : entry.value.toString()), size: 12),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_labelForMetricKey(entry.key), style: Theme.of(context).textTheme.bodyMedium),
                              Text(_stringValue(entry.value is Map ? entry.value['status'] ?? entry.value['value'] ?? entry.value['state'] ?? entry.value : entry.value), style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingAuditLogs
            ? const Center(child: CircularProgressIndicator())
            : (_auditLogsError != null
                ? Text(_auditLogsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.receipt_long, 'Audit Logs (${_filteredAuditLogs.length})', route: '/notifications'),
                      const SizedBox(height: 8),
                      ..._filteredAuditLogs.take(5).map((a) {
                        final action = a['action'] ?? a['event'] ?? a['type'] ?? 'Log';
                        final actor = a['actor'] ?? a['user'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              context.go('/notifications');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(actor.toString().isNotEmpty ? '$action • $actor' : action)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget _buildDeveloperDashboard() => _buildTeamMemberDashboard();
  Widget _buildProjectManagerDashboard() => _buildDeliveryLeadDashboard();
  Widget _buildScrumMasterDashboard() => _buildDeliveryLeadDashboard();
  Widget _buildQAEngineerDashboard() => _buildTeamMemberDashboard();
  Widget _buildStakeholderDashboard() => _buildClientReviewerDashboard();

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
  }

  Widget _buildCardHeader(IconData icon, String label, {String? route}) {
    final row = Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
    if (route == null) return row;
    return InkWell(onTap: () => context.go(route), child: row);
  }

  IconData _iconForMetricKey(String key) {
    final k = key.toLowerCase();
    if (k.contains('uptime')) return Icons.schedule_outlined;
    if (k.contains('cpu')) return Icons.memory;
    if (k.contains('mem') || k.contains('ram')) return Icons.sd_storage_outlined;
    if (k.contains('user')) return Icons.person_outline;
    if (k.contains('session')) return Icons.login;
    if (k.contains('request') || k.contains('api')) return Icons.cloud_outlined;
    if (k.contains('latency')) return Icons.speed;
    if (k.contains('error') || k.contains('fail')) return Icons.error_outline;
    if (k.contains('queue') || k.contains('job')) return Icons.work_outline;
    if (k.contains('db') || k.contains('database')) return Icons.storage;
    if (k.contains('socket')) return Icons.power_outlined;
    if (k.contains('mqtt')) return Icons.sensors;
    if (k.contains('cache')) return Icons.cached;
    return Icons.analytics_outlined;
  }

  String _labelForMetricKey(String key) {
    final s = key.replaceAll('_', ' ').replaceAll('-', ' ');
    return s.isEmpty ? 'Metric' : s[0].toUpperCase() + s.substring(1);
  }

  String _stringValue(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      if (v is int) return v.toString();
      return v.toStringAsFixed(2);
    }
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is List) return '${v.length}';
    if (v is Map) return '${v.length}';
    return v.toString();
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Text(_currentUser?.email ?? ''),
        actions: [TextButton(onPressed: () => context.pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Settings'),
        content: Text('Settings are coming soon.'),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) context.go('/');
  }

  void _setupRealtimeListeners() {
    realtimeService.on('user_role_changed', _handleRoleChanged);
    realtimeService.on('sprint_created', (_) => _loadDashboardSprints());
    realtimeService.on('sprint_updated', (_) => _loadDashboardSprints());
    realtimeService.on('deliverable_created', (_) => _loadDashboardDeliverables());
    realtimeService.on('deliverable_updated', (_) => _loadDashboardDeliverables());
    realtimeService.on('approval_created', (_) => _loadDashboardApprovals());
    realtimeService.on('approval_updated', (_) => _loadDashboardApprovals());
  }

  void _handleRoleChanged(dynamic _) {
    _loadCurrentUser();
  }
}
