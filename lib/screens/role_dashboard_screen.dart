// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fl_chart/fl_chart.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../models/system_metrics.dart';
import '../models/approval_request.dart';
import '../models/sign_off_report.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../services/user_data_service.dart';
import '../services/api_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class RoleDashboardScreen extends ConsumerStatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  ConsumerState<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends ConsumerState<RoleDashboardScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();
  final BackendApiService _backendApiService = BackendApiService();
  final UserDataService _userDataService = UserDataService();
  
  // Audit logs state
  List<dynamic> _auditLogs = [];
  List<dynamic> _filteredAuditLogs = [];
  bool _isLoadingAuditLogs = false;
  bool _isLoadingMoreAuditLogs = false;
  String? _auditLogsError;
  int _auditLogsPage = 1;
  final int _auditLogsPerPage = 20;
  bool _hasMoreAuditLogs = true;
  
  // Filter state variables
  String? _selectedActionFilter;
  String? _selectedUserFilter;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  
  // Search and sorting state
  String _searchQuery = '';
  String _sortField = 'created_at';
  bool _sortAscending = false;

  // Data Analytics state
  bool _isLoadingAnalytics = false;
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _dashboardSprints = [];
  bool _isLoadingDashboardSprints = false;
  List<ApprovalRequest> _dashboardApprovals = [];
  bool _isLoadingDashboardApprovals = false;
  List<Map<String, dynamic>> _dashboardDeliverables = [];
  bool _isLoadingDashboardDeliverables = false;
  List<SignOffReport> _reviewHistoryReports = [];

  // User data state
  List<User> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  // System metrics state
  SystemMetrics? _systemMetrics;
  bool _isLoadingSystemMetrics = false;
  String? _systemMetricsError;
  
  
  
  late final RealtimeService realtimeService;
  
  @override
  void initState() {
    super.initState();
    realtimeService = RealtimeService();
    _loadCurrentUser();
    _loadUsers();
    _loadDashboardSprints();
    _loadDashboardApprovals();
    _loadDashboardDeliverables();
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

  Future<void> _loadCurrentUser() async {
    try {
      // Get the current user from AuthService
      final user = _authService.currentUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        debugPrint('✅ Loaded user: ${user.name} (${user.email})');
        if (_currentUser!.role == UserRole.systemAdmin) {
          _loadSystemMetrics();
          _loadAnalyticsData();
        }
        try {
          final token = ApiClient().getAuthToken();
          if (token != null) {
            await realtimeService.initialize(authToken: token);
          }
        } catch (_) {}
        // Load audit logs after user is loaded
        _loadAuditLogs();
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

  Future<void> _loadAuditLogs({bool loadMore = false}) async {
    if (_isLoadingAuditLogs && !loadMore) return;
    if (_isLoadingMoreAuditLogs && loadMore) return;
    if (!loadMore && !_hasMoreAuditLogs) return;
    
    final int page = loadMore ? _auditLogsPage + 1 : 1;
    final int skip = (page - 1) * _auditLogsPerPage;
    
    setState(() {
      if (loadMore) {
        _isLoadingMoreAuditLogs = true;
      } else {
        _isLoadingAuditLogs = true;
      }
      _auditLogsError = null;
    });

    try {
      final response = await _backendApiService.getAuditLogs(
        skip: skip,
        limit: _auditLogsPerPage,
        action: _selectedActionFilter,
        userId: _selectedUserFilter,
      );
      
      if (response.isSuccess) {
        final data = response.data;
        final logs = data?['audit_logs'] ?? data?['items'] ?? data?['logs'] ?? [];
        final totalCount = data?['total'] ?? data?['total_count'] ?? logs.length;
        
        // Apply date filtering if dates are selected
        List<Map<String, dynamic>> filteredLogs = List<Map<String, dynamic>>.from(logs);
        
        if (_selectedStartDate != null || _selectedEndDate != null) {
          filteredLogs = filteredLogs.where((log) {
            final createdAt = log['created_at'] as String?;
            if (createdAt == null) return false;
            
            try {
              final logDate = DateTime.parse(createdAt);
              
              if (_selectedStartDate != null && logDate.isBefore(_selectedStartDate!)) {
                return false;
              }
              if (_selectedEndDate != null && logDate.isAfter(_selectedEndDate!)) {
                return false;
              }
              
              return true;
            } catch (e) {
              return false;
            }
          }).toList();
        }
        
        setState(() {
          if (loadMore) {
            _auditLogs.addAll(filteredLogs);
            _auditLogsPage = page;
            _hasMoreAuditLogs = _auditLogs.length < totalCount;
          } else {
            _auditLogs = filteredLogs;
            _auditLogsPage = 1;
            _hasMoreAuditLogs = _auditLogs.length < totalCount && filteredLogs.length == _auditLogsPerPage;
          }
        });
        
        // Apply search and sort after loading data
        _applySearchAndSort();
        
        debugPrint('✅ Loaded ${filteredLogs.length} audit logs (page $page, total ${_auditLogs.length}, has more: $_hasMoreAuditLogs)');
      } else {
        setState(() {
          _auditLogsError = response.error ?? 'Failed to load audit logs';
        });
        debugPrint('❌ Error loading audit logs: $_auditLogsError');
      }
    } catch (e) {
      setState(() {
        _auditLogsError = 'Failed to load audit logs: $e';
      });
      debugPrint('❌ Exception loading audit logs: $e');
      } finally {
      setState(() {
        _isLoadingAuditLogs = false;
        _isLoadingMoreAuditLogs = false;
      });
    }
  }

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

  // Removed unused _parseDouble to satisfy analyzer

  Future<void> _loadUsers() async {
    if (_isLoadingUsers) return;
    
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final users = await _userDataService.getUsers(forceRefresh: true);
      setState(() {
        _users = users;
      });
      debugPrint('✅ Loaded ${_users.length} users from API');
    } catch (e) {
      setState(() {
        _usersError = 'Failed to load users: $e';
      });
      debugPrint('❌ Error loading users: $e');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadAnalyticsData() async {
    if (_isLoadingAnalytics) return;
    
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final backendService = BackendApiService();
      final response = await backendService.getAnalytics('performance');
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _analyticsData = response.data!;
          if (_users.isNotEmpty) {
            _analyticsData['active_users'] = _users.length;
          }
        });
        debugPrint('✅ Loaded analytics data: ${_analyticsData.length} keys');
      } else {
        debugPrint('❌ Failed to load analytics data: ${response.statusCode} - ${response.error}');
        final dashboardResponse = await backendService.getDashboardData();
        if (dashboardResponse.isSuccess && dashboardResponse.data != null) {
          setState(() {
            _analyticsData = dashboardResponse.data!;
            if (_users.isNotEmpty) {
              _analyticsData['active_users'] = _users.length;
            }
          });
          debugPrint('✅ Loaded dashboard analytics fallback');
        } else {
          setState(() {
            _analyticsData = {
              'team_performance': [],
              'performance_trends': [],
              'active_users': _users.length,
            };
          });
          debugPrint('⚠️ Using computed analytics fallback');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error loading analytics data: $e');
    } finally {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  Future<void> _loadSystemMetrics() async {
    if (_isLoadingSystemMetrics) return;
    
    setState(() {
      _isLoadingSystemMetrics = true;
      _systemMetricsError = null;
    });

    try {
      final metrics = await ApiService.getSystemMetrics();
      setState(() {
        _systemMetrics = metrics;
      });
      debugPrint('✅ Loaded system metrics: ${metrics.userActivity.activeUsers} active users');
    } catch (e) {
      setState(() {
        _systemMetricsError = 'Failed to load system metrics: $e';
      });
      debugPrint('❌ Error loading system metrics: $e');
    } finally {
      setState(() {
        _isLoadingSystemMetrics = false;
      });
    }
  }

  Future<void> _loadDashboardSprints() async {
    if (_isLoadingDashboardSprints) return;
    setState(() {
      _isLoadingDashboardSprints = true;
    });
    try {
      final sprints = await ApiService.getSprints();
      setState(() {
        _dashboardSprints = sprints;
      });
    } catch (e) {
      debugPrint('Failed to load dashboard sprints: $e');
    } finally {
      setState(() {
        _isLoadingDashboardSprints = false;
      });
    }
  }

  Future<void> _loadDashboardApprovals() async {
    if (_isLoadingDashboardApprovals) return;
    setState(() {
      _isLoadingDashboardApprovals = true;
    });
    try {
      final response = await _backendApiService.getApprovalRequests(page: 1, limit: 20);
      final dynamic raw = response.data;
      final List<dynamic> items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['items'] ?? raw['approvals'] ?? []) : []);
      final approvals = items.whereType<Map>().map((m) => ApprovalRequest.fromJson(Map<String, dynamic>.from(m))).toList();
      setState(() {
        _dashboardApprovals = approvals;
      });
    } catch (e) {
      debugPrint('Failed to load dashboard approvals: $e');
    } finally {
      setState(() {
        _isLoadingDashboardApprovals = false;
      });
    }
  }

  Future<void> _loadDashboardDeliverables() async {
    if (_isLoadingDashboardDeliverables) return;
    setState(() {
      _isLoadingDashboardDeliverables = true;
    });
    try {
      final items = await ApiService.getDeliverables();
      setState(() {
        _dashboardDeliverables = items;
      });
    } catch (e) {
      debugPrint('Failed to load dashboard deliverables: $e');
    } finally {
      setState(() {
        _isLoadingDashboardDeliverables = false;
      });
    }
  }

  Future<void> _loadReviewHistoryReports() async {
    try {
      final backend = BackendApiService();
      final response = await backend.getSignOffReports(page: 1, limit: 20);
      if (response.isSuccess) {
        final reports = backend.parseSignOffReportsFromResponse(response);
        setState(() {
          _reviewHistoryReports = reports;
        });
      }
    } catch (e) {
      debugPrint('Failed to load review history: $e');
    }
  }


  void _applySearchAndSort() {
    // Apply search filter
    List<dynamic> filtered = _auditLogs;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        final action = (log['action'] as String? ?? '').toLowerCase();
        final userEmail = (log['user_email'] as String? ?? '').toLowerCase();
        final entityName = (log['entity_name'] as String? ?? '').toLowerCase();
        final entityType = (log['entity_type'] as String? ?? '').toLowerCase();
        final userRole = (log['user_role'] as String? ?? '').toLowerCase();
        
        return action.contains(query) ||
               userEmail.contains(query) ||
               entityName.contains(query) ||
               entityType.contains(query) ||
               userRole.contains(query);
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      final dynamic aValue = a[_sortField];
      final dynamic bValue = b[_sortField];
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;
      
      if (aValue is String && bValue is String) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      if (aValue is DateTime && bValue is DateTime) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      if (aValue is String && bValue is DateTime) {
        try {
          final aDate = DateTime.parse(aValue);
          return _sortAscending ? aDate.compareTo(bValue) : bValue.compareTo(aDate);
        } catch (e) {
          return _sortAscending ? -1 : 1;
        }
      }
      
      if (aValue is DateTime && bValue is String) {
        try {
          final bDate = DateTime.parse(bValue);
          return _sortAscending ? aValue.compareTo(bDate) : bDate.compareTo(aValue);
        } catch (e) {
          return _sortAscending ? 1 : -1;
        }
      }
      
      return 0;
    });
    
    setState(() {
      _filteredAuditLogs = filtered;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applySearchAndSort();
  }

  void _handleSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = false;
      }
    });
    _applySearchAndSort();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _applySearchAndSort();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Analytics Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Team Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTeamMemberFilterOptions(),
                const SizedBox(height: 16),
                const Text('Metric Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildMetricTypeFilterOptions(),
                const SizedBox(height: 16),
                const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDateRangeFilterOptions(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadAnalyticsData();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamMemberFilterOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          label: const Text('All Members'),
          selected: true,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('John Smith'),
          selected: false,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('Sarah Johnson'),
          selected: false,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('Mike Chen'),
          selected: false,
          onSelected: (selected) {},
        ),
      ],
    );
  }

  Widget _buildMetricTypeFilterOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          label: const Text('Velocity'),
          selected: true,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('Completion'),
          selected: true,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('Progress'),
          selected: true,
          onSelected: (selected) {},
        ),
        FilterChip(
          label: const Text('Blocked Items'),
          selected: true,
          onSelected: (selected) {},
        ),
      ],
    );
  }

  Widget _buildDateRangeFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Handle date selection
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Handle date selection
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // Reset to default date range
          },
          child: const Text('Reset to Default'),
        ),
      ],
    );
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
          _buildTaskProgressOverview(),
          const SizedBox(height: 24),
          _buildMyDeliverables(),
          const SizedBox(height: 24),
          _buildUpcomingDeadlines(),
          const SizedBox(height: 24),
          _buildTeamCollaboration(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildSkillDevelopment(),
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

  Widget _buildTaskProgressOverview() {
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
                  'Task Progress Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshTaskProgress,
                  tooltip: 'Refresh Progress',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar('In Progress Tasks', 0.65, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressBar('Completed Tasks', 0.85, Colors.green),
            const SizedBox(height: 12),
            _buildProgressBar('Pending Review', 0.25, Colors.orange),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressMetric('Total Tasks', '24', Icons.list_alt),
                _buildProgressMetric('Overdue', '3', Icons.warning, Colors.red),
                _buildProgressMetric('Due Today', '2', Icons.today, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildProgressMetric(String title, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? _currentUser!.roleColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }

  void _refreshTaskProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing task progress...')),
    );
  }

  Widget _buildUpcomingDeadlines() {
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
                  'Upcoming Deadlines',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Badge(
                  label: const Text('3'),
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => context.go('/calendar'),
                    tooltip: 'View Calendar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeadlineItem(
              title: 'User Authentication API',
              dueDate: 'Today',
              priority: 'High',
              project: 'Mobile App Development',
            ),
            const SizedBox(height: 12),
            _buildDeadlineItem(
              title: 'Payment Integration Testing',
              dueDate: 'Tomorrow',
              priority: 'Medium',
              project: 'E-commerce Platform',
            ),
            const SizedBox(height: 12),
            _buildDeadlineItem(
              title: 'UI Design Review',
              dueDate: 'Dec 15',
              priority: 'Low',
              project: 'Dashboard Redesign',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/my-deliverables'),
              child: const Text('View All Deadlines'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineItem({
    required String title,
    required String dueDate,
    required String priority,
    required String project,
  }) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(4),
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
                  project,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dueDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
              ),
              Text(
                priority,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: priorityColor,
                    ),
              ),
            ],
          ),
        ],
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

  Widget _buildTeamCollaboration() {
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
                  'Team Collaboration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.group),
                  onPressed: () => context.go('/team-directory'),
                  tooltip: 'Team Directory',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCollaborationMetric(
                  title: 'Team Members',
                  value: '8',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _buildCollaborationMetric(
                  title: 'Active Projects',
                  value: '3',
                  icon: Icons.work,
                  color: Colors.green,
                ),
                _buildCollaborationMetric(
                  title: 'Open Tasks',
                  value: '12',
                  icon: Icons.task,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTeamAvailability(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/team-chat'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat, size: 16),
                  SizedBox(width: 4),
                  Text('Open Team Chat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }

  Widget _buildTeamAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAvailabilityIndicator('Available', Colors.green, 5),
            const SizedBox(width: 8),
            _buildAvailabilityIndicator('Busy', Colors.orange, 2),
            const SizedBox(width: 8),
            _buildAvailabilityIndicator('Offline', Colors.grey, 1),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityIndicator(String status, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    final List<dynamic> rawMembers = (_analyticsData['team_performance'] ?? _analyticsData['members'] ?? _analyticsData['team'] ?? []) as List<dynamic>;
    final List<Map<String, dynamic>> team = rawMembers.map((m) => (m is Map) ? m.cast<String, dynamic>() : <String, dynamic>{}).where((m) => m.isNotEmpty).toList();
    final double avgVelocity = team.isNotEmpty
        ? team.fold<double>(0.0, (sum, m) => sum + ((m['velocity'] ?? m['completed_points'] ?? 0) as num).toDouble()) / team.length
        : 0.0;
    final double avgQuality = team.isNotEmpty
        ? team.fold<double>(0.0, (sum, m) => sum + ((m['qualityScore'] ?? m['quality'] ?? 0) as num).toDouble()) / team.length
        : 0.0;
    final double avgEfficiency = team.isNotEmpty
        ? team.fold<double>(0.0, (sum, m) => sum + ((m['efficiency'] ?? 0) as num).toDouble()) / team.length
        : 0.0;
    final List<dynamic> rawTrends = (_analyticsData['performance_trends'] ?? _analyticsData['trends'] ?? []) as List<dynamic>;
    final List<Map<String, dynamic>> trends = rawTrends.map((t) => (t is Map) ? t.cast<String, dynamic>() : <String, dynamic>{}).where((t) => t.isNotEmpty).toList();
    final double velocityTrend = trends.isNotEmpty
        ? ((trends.last['points'] ?? trends.last['value'] ?? 0) as num).toDouble() - ((trends.first['points'] ?? trends.first['value'] ?? 0) as num).toDouble()
        : 0.0;
    final double qualityTrend = trends.isNotEmpty
        ? ((trends.last['quality'] ?? trends.last['score'] ?? 0) as num).toDouble() - ((trends.first['quality'] ?? trends.first['score'] ?? 0) as num).toDouble()
        : 0.0;
    final double efficiencyTrend = team.length >= 2
        ? ((team.last['efficiency'] ?? 0) as num).toDouble() - ((team.first['efficiency'] ?? 0) as num).toDouble()
        : 0.0;
    
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
                  'Performance Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () => context.go('/performance-dashboard'),
                  tooltip: 'Detailed Analytics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPerformanceMetric(
                    title: 'Velocity',
                    value: '${avgVelocity.toStringAsFixed(1)} pts',
                    trend: '${velocityTrend >= 0 ? '+' : ''}${velocityTrend.toStringAsFixed(1)}',
                    icon: velocityTrend >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: velocityTrend >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildPerformanceMetric(
                    title: 'Quality',
                    value: '${avgQuality.toStringAsFixed(1)}%',
                    trend: '${qualityTrend >= 0 ? '+' : ''}${qualityTrend.toStringAsFixed(1)}',
                    icon: qualityTrend >= 0 ? Icons.verified : Icons.warning,
                    color: qualityTrend >= 0 ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildPerformanceMetric(
                    title: 'Efficiency',
                    value: '${avgEfficiency.toStringAsFixed(1)}%',
                    trend: '${efficiencyTrend >= 0 ? '+' : ''}${efficiencyTrend.toStringAsFixed(1)}',
                    icon: efficiencyTrend >= 0 ? Icons.speed : Icons.timer,
                    color: efficiencyTrend >= 0 ? Colors.orange : Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyPerformanceChart(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/detailed-reports'),
              child: const Text('View Detailed Reports'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildWeeklyPerformanceChart() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Performance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Consistent improvement',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChartBar(40, Colors.blue),
                  _buildChartBar(55, Colors.blue),
                  _buildChartBar(65, Colors.blue),
                  _buildChartBar(75, Colors.green),
                  _buildChartBar(80, Colors.green),
                  _buildChartBar(85, Colors.green),
                  _buildChartBar(87, Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(double height, Color color) {
    return Container(
      width: 6,
      height: height * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildSkillDevelopment() {
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
                  'Skill Development',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.school),
                  onPressed: () => context.go('/learning-path'),
                  tooltip: 'Learning Path',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSkillProgress(
              skill: 'Flutter Development',
              progress: 0.75,
              level: 'Intermediate',
              nextLevel: 'Advanced',
            ),
            const SizedBox(height: 12),
            _buildSkillProgress(
              skill: 'Dart Programming',
              progress: 0.85,
              level: 'Advanced',
              nextLevel: 'Expert',
            ),
            const SizedBox(height: 12),
            _buildSkillProgress(
              skill: 'UI/UX Design',
              progress: 0.60,
              level: 'Intermediate',
              nextLevel: 'Advanced',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Learning',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/recommended-courses'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLearningItem(
              title: 'Advanced State Management',
              type: 'Course',
              duration: '2h 30m',
            ),
            const SizedBox(height: 8),
            _buildLearningItem(
              title: 'Flutter Animations Masterclass',
              type: 'Workshop',
              duration: '1h 45m',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/skill-assessment'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Take Skill Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillProgress({
    required String skill,
    required double progress,
    required String level,
    required String nextLevel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '$level → $nextLevel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: _getProgressColor(progress),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildLearningItem({
    required String title,
    required String type,
    required String duration,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            type == 'Course' ? Icons.menu_book : Icons.workspaces,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
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
                  '$type • $duration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
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

  // Delivery Lead Dashboard Methods
  Widget _buildTeamMetrics() {
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
                  'Team Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: 'current_sprint',
                      onChanged: (String? newValue) {
                        // Time period selection handler
                      },
                      items: <String>['last_7_days', 'last_30_days', 'last_90_days', 'current_sprint']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.replaceAll('_', ' ').replaceAllMapped(
                            RegExp(r'\b\w'), 
                            (match) => match.group(0)!.toUpperCase(),
                          ),),
                        );
                      }).toList(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      underline: Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        _showFilterDialog();
                      },
                      tooltip: 'Filter Options',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricCard(
                  title: 'Sprint Progress',
                  value: () {
                    final s = _selectCurrentSprint();
                    final planned = _parseInt(s?['planned_points']) ?? _parseInt(s?['committed_points']) ?? _parseInt(s?['committedPoints']) ?? 0;
                    final completed = _parseInt(s?['completed_points']) ?? _parseInt(s?['completedPoints']) ?? 0;
                    final pct = planned > 0 ? ((completed / planned) * 100).toStringAsFixed(0) : '0';
                    return '$pct%';
                  }(),
                  icon: Icons.timeline,
                  color: Colors.blue,
                  trend: '',
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  title: 'Team Velocity',
                  value: () {
                    final List<dynamic> rawMembers = (_analyticsData['team_performance'] ?? _analyticsData['members'] ?? _analyticsData['team'] ?? []) as List<dynamic>;
                    final velocities = rawMembers.map((m) {
                      final mm = (m is Map) ? m : <String, dynamic>{};
                      return _parseInt(mm['velocity']) ?? 0;
                    }).toList();
                    final avg = velocities.isNotEmpty ? (velocities.reduce((a,b)=>a+b) / velocities.length).toStringAsFixed(1) : '0.0';
                    return '$avg pts';
                  }(),
                  icon: Icons.speed,
                  color: Colors.green,
                  trend: '',
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  title: 'Work Completed',
                  value: () {
                    final s = _selectCurrentSprint();
                    final planned = _parseInt(s?['planned_points']) ?? _parseInt(s?['committed_points']) ?? _parseInt(s?['committedPoints']) ?? 0;
                    final completed = _parseInt(s?['completed_points']) ?? _parseInt(s?['completedPoints']) ?? 0;
                    return '$completed/$planned';
                  }(),
                  icon: Icons.check_circle,
                  color: Colors.orange,
                  trend: '',
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  title: 'Blocked Items',
                  value: () {
                    final List<dynamic> rawMembers = (_analyticsData['team_performance'] ?? _analyticsData['members'] ?? _analyticsData['team'] ?? []) as List<dynamic>;
                    final blocked = rawMembers.map((m) {
                      final mm = (m is Map) ? m : <String, dynamic>{};
                      return _parseInt(mm['blockedItems']) ?? _parseInt(mm['blocked']) ?? 0;
                    }).toList();
                    final sum = blocked.isNotEmpty ? blocked.reduce((a,b)=>a+b) : 0;
                    return sum.toString();
                  }(),
                  icon: Icons.block,
                  color: Colors.red,
                  trend: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                  'Current Sprint Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    final sprint = _selectCurrentSprint();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SprintOverviewDetailPage(sprint: sprint),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSprintProgressBar(),
            const SizedBox(height: 16),
            
            // Burn-down Chart Section
            Text(
              'Sprint Burn-down Chart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildBurnDownChart(),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildSprintMetricCard(
                  title: 'Days Remaining',
                  value: _computeDaysRemaining(),
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildSprintMetricCard(
                  title: 'Points Burned',
                  value: _computePointsBurned(),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildSprintMetricCard(
                  title: 'Avg. Daily',
                  value: _computeAvgDailyBurn(),
                  icon: Icons.analytics,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingReviews() {
    final pending = _dashboardApprovals.where((a) => a.status == ApprovalStatus.pending).toList();
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
                  'Pending Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Badge(
                  label: Text(pending.length.toString()),
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardApprovals,
                    tooltip: 'Refresh Reviews',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pending.take(3).map((r) => _buildReviewItem(
                  title: r.deliverableTitle.isNotEmpty ? r.deliverableTitle : 'Deliverable',
                  requester: r.requesterName.isNotEmpty ? r.requesterName : 'Unknown',
                  daysPending: DateTime.now().difference(r.requestedAt).inDays,
                  priority: 'High',
                ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.go('/approvals'),
                child: const Text('View Pending Reviews'),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Helper methods for Delivery Lead Dashboard
  Widget _buildSprintProgressBar() {
    final s = _selectCurrentSprint();
    final planned = _parseInt(s?['planned_points']) ?? _parseInt(s?['committed_points']) ?? _parseInt(s?['committedPoints']) ?? 0;
    final completed = _parseInt(s?['completed_points']) ?? _parseInt(s?['completedPoints']) ?? 0;
    final rate = planned > 0 ? (completed / planned) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sprint Progress: ${(rate * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: rate,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Start',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'End',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSprintMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        color: color.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildReviewItem({
    required String title,
    required String requester,
    required int daysPending,
    required String priority,
  }) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              color: priorityColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: $requester',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: priorityColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysPending days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReviewMetrics() {
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
                  'Review Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadReviewMetrics,
                  tooltip: 'Refresh Metrics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Review metrics summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReviewMetricCard(
                  title: 'Total Reviews',
                  value: '42',
                  icon: Icons.rate_review,
                  color: Colors.blue,
                  trend: '+15%',
                ),
                _buildReviewMetricCard(
                  title: 'Avg. Turnaround',
                  value: '1.8 days',
                  icon: Icons.timer,
                  color: Colors.green,
                  trend: '-0.5 days',
                ),
                _buildReviewMetricCard(
                  title: 'Approval Rate',
                  value: '87%',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                  trend: '+3%',
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Review trends chart
            _buildReviewTrendsChart(),
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
                Badge(
                  label: Text((_dashboardApprovals.where((a) => a.status == ApprovalStatus.pending).length).toString()),
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardApprovals,
                    tooltip: 'Refresh Approvals',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._dashboardApprovals
              .where((r) => r.status == ApprovalStatus.pending)
              .take(5)
              .map((r) => _buildPendingApprovalItem(
                    title: r.deliverableTitle.isNotEmpty ? r.deliverableTitle : 'Deliverable',
                    submittedBy: r.requesterName.isNotEmpty ? r.requesterName : 'Unknown',
                    daysPending: DateTime.now().difference(r.requestedAt).inDays,
                    priority: 'High',
                    type: 'Approval',
                  ),
              ),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/approvals'),
                child: const Text('View All Pending Approvals'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRecentSubmissions() {
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
                  'Recent Submissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showRecentSubmissionsFilter,
                  tooltip: 'Filter Submissions',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._dashboardDeliverables
                .take(4)
                .map((d) => _buildRecentSubmissionItem(
                      title: d['title']?.toString() ?? 'Untitled',
                      submittedBy: d['submitted_by']?.toString() ?? d['submittedBy']?.toString() ?? 'Unknown',
                      submittedDate: _parseDate(d['submitted_at'] ?? d['submittedAt']) ?? DateTime.now(),
                      status: d['status']?.toString() ?? 'submitted',
                      type: 'Deliverable',
                    ),
                ),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/report-repository'),
                child: const Text('View All Submissions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReviewHistory() {
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
                  'Review History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showReviewHistoryFilter,
                      tooltip: 'Filter History',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _exportReviewHistory,
                      tooltip: 'Export History',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._reviewHistoryReports
                .take(5)
                .map((r) => _buildReviewHistoryItem(
                      title: r.reportTitle,
                      reviewedBy: r.reviewedBy ?? 'Unknown',
                      reviewDate: r.reviewedAt ?? r.submittedAt ?? r.createdAt,
                      status: r.statusDisplayName,
                      reviewTime: (() {
                        if (r.submittedAt != null && r.reviewedAt != null) {
                          final mins = r.reviewedAt!.difference(r.submittedAt!).inMinutes;
                          return '$mins min';
                        }
                        return '-';
                      })(),
                      score: (() {
                        final perf = r.sprintPerformanceData;
                        if (perf != null && perf.isNotEmpty) {
                          final match = RegExp(r'quality\s*:\s*(\d+)').firstMatch(perf);
                          if (match != null) {
                            return int.tryParse(match.group(1)!) ?? 0;
                          }
                        }
                        return 0;
                      })(),
                    ),
                ),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/report-repository'),
                child: const Text('View Complete History'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTeamPerformance() {
    final List<dynamic> rawMembers = (_analyticsData['team_performance'] ?? _analyticsData['members'] ?? _analyticsData['team'] ?? []) as List<dynamic>;
    final List<Map<String, dynamic>> teamPerformanceData = rawMembers.map((m) {
      final Map<String, dynamic> member = (m is Map)
          ? Map<String, dynamic>.from(m)
          : <String, dynamic>{};
      final int completedPoints = _parseInt(member['completedPoints']) ?? _parseInt(member['completed_points']) ?? 0;
      final int qualityScore = _parseInt(member['qualityScore']) ?? _parseInt(member['quality']) ?? 0;
      final int velocity = _parseInt(member['velocity']) ?? 0;
      final int blockedItems = _parseInt(member['blockedItems']) ?? _parseInt(member['blocked']) ?? 0;
      final String avgCycleTime = (member['avgCycleTime'] ?? member['cycle_time'] ?? '').toString();
      final String trend = (member['trend'] ?? '').toString();
      return {
        'name': (member['name'] ?? member['user_name'] ?? member['email'] ?? 'Unknown').toString(),
        'role': (member['role'] ?? member['user_role'] ?? '').toString(),
        'completedPoints': completedPoints,
        'qualityScore': qualityScore,
        'velocity': velocity,
        'blockedItems': blockedItems,
        'avgCycleTime': avgCycleTime,
        'trend': trend.isEmpty ? 'stable' : trend,
        'avatarUrl': member['avatarUrl'] ?? member['avatar_url'],
      };
    }).toList();

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
                  'Team Performance Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showTeamPerformanceFilterDialog(),
                  tooltip: 'Filter Team Performance',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamMetricCard(
                  title: 'Total Points',
                  value: teamPerformanceData.fold<int>(0, (sum, m) => sum + (m['completedPoints'] as int)).toString(),
                  icon: Icons.assessment,
                  color: Colors.blue,
                ),
                _buildTeamMetricCard(
                  title: 'Avg Quality',
                  value: teamPerformanceData.isNotEmpty
                      ? '${(teamPerformanceData.fold<int>(0, (sum, m) => sum + (m['qualityScore'] as int)) / teamPerformanceData.length).toStringAsFixed(1)}%'
                      : '—',
                  icon: Icons.star,
                  color: Colors.green,
                ),
                _buildTeamMetricCard(
                  title: 'Avg Velocity',
                  value: teamPerformanceData.isNotEmpty
                      ? (teamPerformanceData.fold<int>(0, (sum, m) => sum + (m['velocity'] as int)) / teamPerformanceData.length).toStringAsFixed(1)
                      : '—',
                  icon: Icons.speed,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Performance table header
            const Row(
              children: [
                Expanded(flex: 2, child: Text('Team Member', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Quality', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Velocity', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Cycle Time', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Blocked', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40), // Space for action icons
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            
            // Team member performance list
            ...teamPerformanceData.map((member) => _buildTeamPerformanceRow(member)),
            
            const SizedBox(height: 16),
            
            // Performance trends chart
            _buildTeamPerformanceTrendsChart(),
          ],
        ),
      ),
    );
  }
  Widget _buildSystemMetrics() {
    if (_isLoadingSystemMetrics) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (_systemMetricsError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load system metrics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _systemMetricsError!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSystemMetrics,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_systemMetrics == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('No system metrics data available')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 40, // Account for padding
                ),
                child: Row(
                  children: [
        _buildMetricCard(
          title: 'Active Users',
          value: (_users.isNotEmpty
                  ? _users.length
                  : (_analyticsData['active_users'] ?? _systemMetrics!.userActivity.activeUsers))
              .toString(),
          icon: Icons.people,
          color: Colors.blue,
          trend: (_analyticsData['active_users_trend'] != null)
              ? '${_analyticsData['active_users_trend'] > 0 ? '+' : ''}${(_analyticsData['active_users_trend']).toString()}%'
              : '—',
        ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      title: 'API Requests',
                      value: (_analyticsData['api_requests'] ?? _systemMetrics!.database.queryCount).toString(),
                      icon: Icons.api,
                      color: Colors.green,
                      trend: (_analyticsData['api_requests_trend'] != null)
                          ? '${_analyticsData['api_requests_trend'] > 0 ? '+' : ''}${(_analyticsData['api_requests_trend']).toString()} today'
                          : '—',
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      title: 'Response Time',
                      value: '${_systemMetrics!.performance.responseTime}ms',
                      icon: Icons.speed,
                      color: Colors.orange,
                      trend: '—',
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      title: 'Uptime',
                      value: '${_systemMetrics!.performance.uptime.toStringAsFixed(1)}%',
                      icon: Icons.timer,
                      color: Colors.purple,
                      trend: '—',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSystemUsageChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
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
                  'User Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddUserDialog,
                  tooltip: 'Add User',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUserList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_usersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load users',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _usersError!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_users.isEmpty)
          const Center(
            child: Text('No users found'),
          )
        else
          ..._users.map((user) => _buildUserListItem(user)),
      ],
    );
  }

  Widget _buildUserListItem(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.roleColor,
              child: Icon(
                user.roleIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        user.roleIcon,
                        size: 14,
                        color: user.roleColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.roleDisplayName,
                        style: TextStyle(
                          color: user.roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: user.isActive ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: user.isActive ? Colors.green : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editUser(user);
                } else if (value == 'delete') {
                  _confirmDeleteUser(user);
                } else if (value == 'view') {
                  _showUserDetails(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSystemHealth() {
    VoidCallback? showHealthHistory;
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
                  'System Health',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: showHealthHistory,
                      tooltip: 'View Health History',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshSystemHealth,
                      tooltip: 'Refresh Status',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // System Status Overview
            _buildSystemStatusOverview(),
            const SizedBox(height: 16),
            
            // Service Health Indicators
            Text(
              'Service Health',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildHealthIndicator(
                  title: 'Database',
                  status: 'Healthy',
                  icon: Icons.storage,
                  color: Colors.green,
                ),
                _buildHealthIndicator(
                  title: 'API Server',
                  status: 'Healthy',
                  icon: Icons.cloud,
                  color: Colors.green,
                ),
                _buildHealthIndicator(
                  title: 'Cache',
                  status: 'Warning',
                  icon: Icons.memory,
                  color: Colors.orange,
                ),
                _buildHealthIndicator(
                  title: 'Storage',
                  status: 'Critical',
                  icon: Icons.sd_storage,
                  color: Colors.red,
                ),
                _buildHealthIndicator(
                  title: 'Email Service',
                  status: 'Healthy',
                  icon: Icons.email,
                  color: Colors.green,
                ),
                _buildHealthIndicator(
                  title: 'Auth Service',
                  status: 'Healthy',
                  icon: Icons.security,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Resource Usage
            _buildResourceUsage(),
            const SizedBox(height: 16),
            
            // Performance Metrics
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceUsage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resource Usage',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildUsageIndicator(
              title: 'CPU',
              usage: _systemMetrics?.performance.cpuUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.cpuUsage ?? 0.0),
            ),
            _buildUsageIndicator(
              title: 'Memory',
              usage: _systemMetrics?.performance.memoryUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.memoryUsage ?? 0.0),
            ),
            _buildUsageIndicator(
              title: 'Disk',
              usage: _systemMetrics?.performance.diskUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.diskUsage ?? 0.0),
            ),
          ],
        ),
      ],
    );
  }

  Color _getUsageColor(double usage) {
    if (usage < 70) return Colors.green;
    if (usage < 85) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUsageIndicator({
    required String title,
    required int usage,
    required int max,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            Positioned.fill(
              child: CircularProgressIndicator(
                value: usage / max,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '$usage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _refreshSystemHealth() {
    // Simulate refreshing system health data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System health status refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSystemStatusOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusItem(
                  title: 'System Status',
                  status: _systemMetrics?.systemHealth.toString().split('.').last ?? 'Loading...',
                  icon: Icons.check_circle,
                  color: _systemMetrics?.systemHealth == SystemHealthStatus.healthy 
                      ? Colors.green : Colors.orange,
                ),
                _buildStatusItem(
                  title: 'Uptime',
                  status: _systemMetrics?.performance.uptime != null 
                      ? '${_systemMetrics!.performance.uptime.toStringAsFixed(1)}h' : 'Loading...',
                  icon: Icons.timer,
                  color: Colors.blue,
                ),
                _buildStatusItem(
                  title: 'Response Time',
                  status: _systemMetrics?.performance.responseTime != null 
                      ? '${_systemMetrics!.performance.responseTime}ms' : 'Loading...',
                  icon: Icons.speed,
                  color: _systemMetrics?.performance.responseTime != null && _systemMetrics!.performance.responseTime < 100 
                      ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildAuditLogs() {
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
                  'Audit Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showAuditFilterDialog,
                      tooltip: 'Filter Logs',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _exportAuditLogs,
                      tooltip: 'Export Logs',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search audit logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _handleSearch,
            ),
            const SizedBox(height: 16),
            
            // Sorting controls
            Row(
              children: [
                const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortField,
                  items: const [
                    DropdownMenuItem(value: 'created_at', child: Text('Date')),
                    DropdownMenuItem(value: 'action', child: Text('Action')),
                    DropdownMenuItem(value: 'user_email', child: Text('User')),
                    DropdownMenuItem(value: 'entity_name', child: Text('Entity')),
                  ],
                  onChanged: (value) => _handleSort(value!),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () => _handleSort(_sortField),
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Results count
            if (_searchQuery.isNotEmpty)
              Text(
                'Found \${_filteredAuditLogs.length} results for "\$_searchQuery"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 400, // Fixed height for the audit log list
              child: _buildAuditLogList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalItem({
    required String title,
    required String submittedBy,
    required int daysPending,
    required String priority,
    required String type,
  }) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted by: $submittedBy • $type',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$daysPending day${daysPending > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: daysPending > 3 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () => _reviewApproval(title),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSubmissionItem({
    required String title,
    required String submittedBy,
    required DateTime submittedDate,
    required String status,
    required String type,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'under review':
        statusColor = Colors.blue;
        break;
      case 'revisions requested':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    final timeAgo = _formatTimeAgo(submittedDate);

    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By: $submittedBy • $type • $timeAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () => _viewSubmission(title),
                  tooltip: 'View Details',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.greenAccent;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.orangeAccent;
    return Colors.red;
  }

  

  void _showRecentSubmissionsFilter() {
    // TODO: Implement recent submissions filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showing submissions filter...')),
    );
  }

  void _showReviewHistoryFilter() {
    // TODO: Implement review history filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showing review history filter...')),
    );
  }

  void _exportReviewHistory() {
    // TODO: Implement review history export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting review history...')),
    );
  }

  void _reviewApproval(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Approval'),
        content: const Text('Review details for: \$title'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Approval reviewed: \$title')),
              );
            },
            child: const Text('Complete Review'),
          ),
        ],
      ),
    );
  }

  

  

  







  void _loadReviewMetrics() {
    // TODO: Implement review metrics loading functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing review metrics...')),
    );
  }

  Widget _buildReviewMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final isPositiveTrend = trend.contains('+') || trend.contains('-') && !trend.contains('days');
    final trendColor = isPositiveTrend ? Colors.green : Colors.red;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                color: trendColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTrendsChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Trends (Last 30 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Review trends chart will be implemented here',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void _viewSubmission(String title) {
    // TODO: Implement submission view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing submission: $title')),
    );
  }

  Widget _buildReviewHistoryItem({
    required String title,
    required String reviewedBy,
    required DateTime reviewDate,
    required String status,
    required String reviewTime,
    required int score,
  }) {
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'revisions requested':
        statusColor = Colors.orange;
        statusIcon = Icons.info;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    final timeAgo = _formatTimeAgo(reviewDate);

    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reviewed by: $reviewedBy • $timeAgo • $reviewTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getScoreColor(score)),
                  ),
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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

  void _showAddUserDialog() {
    _createNewUser();
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 24),
                SizedBox(width: 12),
                Text('System Administration'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'System Status', icon: Icon(Icons.monitor_heart)),
                        Tab(text: 'Backup & Restore', icon: Icon(Icons.backup)),
                        Tab(text: 'Maintenance', icon: Icon(Icons.settings)),
                        Tab(text: 'Configuration', icon: Icon(Icons.tune)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSystemStatusTab(),
                          _buildBackupRestoreTab(),
                          _buildMaintenanceTab(),
                          _buildConfigurationTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemStatusTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Health Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHealthIndicator(
                title: 'Database',
                status: 'Online',
                icon: Icons.storage,
                color: Colors.green,
              ),
              _buildHealthIndicator(
                title: 'API Server',
                status: 'Online',
                icon: Icons.cloud,
                color: Colors.green,
              ),
              _buildHealthIndicator(
                title: 'Memory',
                status: 'Normal',
                icon: Icons.memory,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'System Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildMetricCard(
                title: 'Active Users',
                value: '\${_systemMetrics!.userActivity.activeUsers}',
                icon: Icons.people,
                color: Colors.blue,
                trend: '+\${_systemMetrics!.userActivity.newRegistrations} today',
              ),
              _buildMetricCard(
                title: 'Database Size',
                value: '\${_systemMetrics!.database.sizeMB.toStringAsFixed(1)} MB',
                icon: Icons.data_usage,
                color: Colors.purple,
                trend: '+\${_systemMetrics!.database.growthRate.toStringAsFixed(1)} MB',
              ),
              _buildMetricCard(
                title: 'Uptime',
                value: '\${_formatUptime(_systemMetrics!.performance.uptime)}',
                icon: Icons.timer,
                color: Colors.orange,
                trend: '\${_systemMetrics!.systemHealth.uptimePercentage.toStringAsFixed(1)}%',
              ),
              _buildMetricCard(
                title: 'API Requests',
                value: '\${_systemMetrics!.database.queryCount}',
                icon: Icons.api,
                color: Colors.green,
                trend: '+\${_systemMetrics!.database.queryRate.toStringAsFixed(0)} today',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestoreTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Database Backup & Restore',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Backup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Last backup: 2 hours ago'),
                  const Text('Size: 42.1 MB'),
                  const Text('Status: Completed'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _createBackup(),
                        icon: const Icon(Icons.backup),
                        label: const Text('Create Backup'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showRestoreDialog(),
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Backup Schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Automatic Daily Backup'),
            value: true,
            onChanged: (value) {},
          ),
          const SizedBox(height: 8),
          const Text('Next scheduled backup: Today at 02:00 AM'),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Maintenance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maintenance Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('When enabled, only administrators can access the system.'),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Maintenance Mode'),
                    value: false,
                    onChanged: (value) => _toggleMaintenanceMode(value),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'System Operations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _clearCache(),
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Clear Cache'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _optimizeDatabase(),
                        icon: const Icon(Icons.build),
                        label: const Text('Optimize Database'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _runDiagnostics(),
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Run Diagnostics'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'General Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable User Registration'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Require Email Verification'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Enable Audit Logging'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Security Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Session Timeout (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '30',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password Complexity Requirements',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: 'Minimum 8 characters',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // System administration methods
  Future<void> _createBackup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating system backup...')),
      );
      
      // Call backend API to create backup
      final response = await _backendApiService.createBackup();
      
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating backup: $e')),
      );
    }
  }

  Future<void> _showRestoreDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text('This will restore the system from the latest backup. All current data will be replaced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _restoreBackup();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring from backup...')),
      );
      
      // Call backend API to restore backup
      final response = await _backendApiService.restoreBackup();
      
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System restored successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring backup: $e')),
      );
    }
  }

  Future<void> _toggleMaintenanceMode(bool enabled) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? 'Enabling maintenance mode...' : 'Disabling maintenance mode...')),
      );
      
      // Call backend API to toggle maintenance mode
      final response = await _backendApiService.updateSystemSettings({
        'maintenance_mode': enabled,
      });
      
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enabled ? 'Maintenance mode enabled!' : 'Maintenance mode disabled!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update maintenance mode: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating maintenance mode: \$e')),
      );
    }
  }

  // Missing method implementations
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings dialog will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (trend != null)
              Text(
                trend,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: trend.startsWith('+') ? Colors.green : 
                             trend.startsWith('-') ? Colors.red : Colors.grey,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemUsageChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Usage Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildUsageChartItem(
              title: 'CPU Usage',
              usage: _systemMetrics?.performance.cpuUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.cpuUsage ?? 0.0),
              trend: '${_systemMetrics != null ? _systemMetrics!.performance.cpuUsage.toStringAsFixed(1) : '0.0'}% avg',
            ),
            const SizedBox(height: 12),
            _buildUsageChartItem(
              title: 'Memory Usage',
              usage: _systemMetrics?.performance.memoryUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.memoryUsage ?? 0.0),
              trend: '${_systemMetrics != null ? _systemMetrics!.performance.memoryUsage.toStringAsFixed(1) : '0.0'}% avg',
            ),
            const SizedBox(height: 12),
            _buildUsageChartItem(
              title: 'Disk Usage',
              usage: _systemMetrics?.performance.diskUsage.round() ?? 0,
              max: 100,
              color: _getUsageColor(_systemMetrics?.performance.diskUsage ?? 0.0),
              trend: '${_systemMetrics != null ? _systemMetrics!.performance.diskUsage.toStringAsFixed(1) : '0.0'}% avg',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last updated: ${_systemMetrics?.lastUpdated.toString().substring(11, 16) ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _refreshSystemUsage,
                  tooltip: 'Refresh usage data',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChartItem({
    required String title,
    required int usage,
    required int max,
    required Color color,
    required String trend,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '$usage%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: (usage / max) * MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$usage% of $max%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trend.startsWith('+') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  void _refreshSystemUsage() {
    _loadSystemMetrics();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System usage data refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHealthIndicator({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _editUser(User user) {
    final formKey = GlobalKey<FormState>();
    String firstName = user.name.split(' ').first;
    String lastName = user.name.split(' ').length > 1 ? user.name.split(' ').last : '';
    String email = user.email;
    String selectedRole = user.role.name;
    bool isActive = user.isActive;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit User'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: firstName,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                      onChanged: (value) => firstName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: lastName,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                      onChanged: (value) => lastName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onChanged: (value) => email = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'systemAdmin', child: Text('System Admin')),
                        DropdownMenuItem(value: 'deliveryLead', child: Text('Delivery Lead')),
                        DropdownMenuItem(value: 'teamMember', child: Text('Team Member')),
                        DropdownMenuItem(value: 'clientReviewer', child: Text('Client Reviewer')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isActive,
                          onChanged: (value) {
                            setState(() {
                              isActive = value ?? false;
                            });
                          },
                        ),
                        const Text('Active Account'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isLoading = true);
                    
                    try {
                      // Update user via API
                      final updatedUser = await _userDataService.updateUser(
                        userId: user.id,
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        role: selectedRole,
                        isActive: isActive,
                      );
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User \${updatedUser.name} updated successfully')),
                      );
                      
                      // Refresh users list
                      _loadUsers();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update user: \${e.toString()}')),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(User user) {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete User'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete \${user.name}? This action cannot be undone.'),
                SizedBox(height: 8),
                Text('⚠️ Warning: This will permanently remove the user account and all associated data.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : () async {
                  setState(() => isLoading = true);
                  
                  try {
                    // Delete user via API
                    await _userDataService.deleteUser(user.id);
                    
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User \${user.name} deleted successfully')),
                    );
                    
                    // Refresh users list
                    _loadUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete user: \${e.toString()}')),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Delete User'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(user.roleIcon, color: user.roleColor, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'User Details: \${user.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              _buildUserProfileSection(user),
              const SizedBox(height: 16),
              
              // Account Status Section
              _buildAccountStatusSection(user),
              const SizedBox(height: 16),
              
              // Activity & Statistics Section
              _buildActivitySection(user),
              const SizedBox(height: 16),
              
              // Permissions Overview
              _buildPermissionsSection(user),
              const SizedBox(height: 16),
              
              // Project Assignments
              _buildProjectsSection(user),
            ],
          ),
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

  Widget _buildUserProfileSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Email', user.email),
        _buildDetailRow('User ID', user.id),
        _buildDetailRow('Full Name', user.name),
        _buildDetailRow('Role', user.roleDisplayName),
        if (user.avatarUrl != null) _buildDetailRow('Avatar', 'Available'),
      ],
    );
  }

  Widget _buildAccountStatusSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              user.isActive ? Icons.check_circle : Icons.cancel,
              color: user.isActive ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              user.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: user.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              user.emailVerified ? Icons.verified : Icons.email,
              color: user.emailVerified ? Colors.blue : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              user.emailVerified ? 'Email Verified' : 'Email Not Verified',
              style: TextStyle(
                color: user.emailVerified ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        if (user.emailVerifiedAt != null)
          _buildDetailRow('Verified On', _formatUserDate(user.emailVerifiedAt!)),
      ],
    );
  }

  Widget _buildActivitySection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity & Statistics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Member Since', _formatUserDate(user.createdAt)),
        if (user.lastLoginAt != null)
          _buildDetailRow('Last Login', _formatUserDate(user.lastLoginAt!)),
        _buildDetailRow('Project Count', user.projectIds.length.toString()),
        _buildDetailRow('Account Age', _calculateAccountAge(user.createdAt)),
      ],
    );
  }

  Widget _buildPermissionsSection(User user) {
    final permissions = PermissionManager.getPermissionsForRole(user.role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '\${permissions.length} permissions granted',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: permissions.take(5).map((permission) {
            return Chip(
              label: Text(permission.name),
              // ignore: deprecated_member_use
              backgroundColor: user.roleColor.withOpacity(0.1),
              labelStyle: TextStyle(color: user.roleColor, fontSize: 12),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        if (permissions.length > 5)
          const Text(
            '+\${permissions.length - 5} more permissions...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildProjectsSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Assignments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (user.projectIds.isEmpty)
          const Text(
            'No projects assigned',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned to \${user.projectIds.length} projects',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                user.projectIds.join(', '),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 100,
            child: Text(
              '\$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUserDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _calculateAccountAge(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final days = difference.inDays;
    
    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months months';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      return '$years years${remainingMonths > 0 ? ' $remainingMonths months' : ''}';
    }
  }

  void _createNewProject() {
    final formKey = GlobalKey<FormState>();
    String projectName = '';
    String projectDescription = '';
    String projectKey = '';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Project'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project name';
                        }
                        return null;
                      },
                      onChanged: (value) => projectName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Project Key',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project key';
                        }
                        if (value.length > 10) {
                          return 'Project key must be 10 characters or less';
                        }
                        return null;
                      },
                      onChanged: (value) => projectKey = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project description';
                        }
                        return null;
                      },
                      onChanged: (value) => projectDescription = value,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isLoading = true);
                    
                    try {
                      // Create project via API
                      final response = await _backendApiService.createProject({
                        'name': projectName,
                        'key': projectKey,
                        'description': projectDescription,
                      });
                      
                      if (response.isSuccess) {
                        final newProject = response.data;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Project ${newProject['name']} created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create project: ${response.error}')),
                        );
                      }
                      
                      // Refresh projects list if needed
                      // _loadProjects();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create project: ${e.toString()}')),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Project'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createNewUser() {
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String email = '';
    String password = '';
    String confirmPassword = '';
    String selectedRole = 'client';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New User'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                      onChanged: (value) => firstName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                      onChanged: (value) => lastName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onChanged: (value) => email = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onChanged: (value) => password = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != password) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onChanged: (value) => confirmPassword = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'client', child: Text('Client')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'system_admin', child: Text('System Admin')),
                        DropdownMenuItem(value: 'auditor', child: Text('Auditor')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isLoading = true);
                    
                    try {
                      // Create user via API
                      final name = '$firstName $lastName'.trim();
                      final result = await _userDataService.createUser(
                        email: email,
                        name: name,
                        role: selectedRole,
                        password: password,
                      );
                      
                      if (result['success'] == true) {
                        final newUser = result['data'] as User;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User ${newUser.name} created successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create user: ${result['error']}')),
                        );
                      }
                      
                      // Refresh users list
                      _loadUsers();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create user: ${e.toString()}')),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create User'),
              ),
            ],
          );
        },
      ),
    );
  }
  void _showAuditFilterDialog() {
    final List<String> actionTypes = [
      'All Actions',
      'created',
      'updated',
      'deleted',
      'approved',
      'rejected',
      'submitted',
      'viewed',
      'logged_in',
      'logged_out',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Audit Logs'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Action Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedActionFilter ?? 'All Actions',
                    items: actionTypes.map((action) {
                      return DropdownMenuItem<String>(
                        value: action,
                        child: Text(action == 'All Actions' ? 'All Actions' : action.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedActionFilter = value == 'All Actions' ? null : value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('User Email:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _selectedUserFilter,
                    decoration: const InputDecoration(
                      hintText: 'Filter by user email',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      _selectedUserFilter = value.isEmpty ? null : value;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Start date',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, size: 20),
                              onPressed: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    _selectedStartDate = selectedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: _selectedStartDate != null
                                ? '${_selectedStartDate!.year}-${_selectedStartDate!.month.toString().padLeft(2, '0')}-${_selectedStartDate!.day.toString().padLeft(2, '0')}'
                                : '',
                        
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'End date',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today, size: 20),
                              onPressed: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedEndDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    _selectedEndDate = selectedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: _selectedEndDate != null ? _selectedEndDate!.toString() : '',



                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  if (_selectedStartDate != null || _selectedEndDate != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStartDate = null;
                          _selectedEndDate = null;
                        });
                      },
                      child: const Text('Clear date range'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear all filters
                  setState(() {
                    _selectedActionFilter = null;
                    _selectedUserFilter = null;
                    _selectedStartDate = null;
                    _selectedEndDate = null;
                  });
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadAuditLogs();
                },
                child: const Text('Apply Filters'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _exportAuditLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Audit Logs'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToCSV();
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportToPDF();
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogList() {
    if (_isLoadingAuditLogs) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_auditLogsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load audit logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _auditLogsError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAuditLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bool hasActiveFilters = _selectedActionFilter != null ||
        _selectedUserFilter != null ||
        _selectedStartDate != null ||
        _selectedEndDate != null ||
        _searchQuery.isNotEmpty;

    final List<dynamic> displayLogs = hasActiveFilters ? _filteredAuditLogs : _auditLogs;

    if (displayLogs.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasActiveFilters)
            Column(
              children: [
                const Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No audit logs match your filters'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear all filters'),
                ),
              ],
            )
          else
            const Text('No audit logs available'),
        ],
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing filtered results (\${displayLogs.length} logs)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
        ...displayLogs.map((log) => _buildAuditLogItem(log)),
        if (_hasMoreAuditLogs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoadingMoreAuditLogs
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loadMoreAuditLogs,
                    child: const Text('Load More'),
                  ),
          )
        else if (_auditLogs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'All \${_auditLogs.length} logs loaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildAuditLogItem(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? 'Unknown Action';
    final entityName = log['entity_name'] as String?;
    final createdAt = log['created_at'] as String?;
    DateTime? timestamp;
    if (createdAt != null) {
      try {
        timestamp = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing timestamp: \$e');
      }
    }
    
    // Build details text from available fields
    final details = StringBuffer();
    if (entityName != null) {
      details.write('Entity: \$entityName');
    }
    if (log['entity_type'] != null) {
      if (details.isNotEmpty) details.write(', ');
      details.write('Type: ${log['entity_type']}');
    }
    if (log['user_role'] != null) {
      if (details.isNotEmpty) details.write(', ');
      details.write('Role: ${log['user_role']}');
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  action,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (timestamp != null)
                  Text(
                    _formatDateTime(timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'User: ${log['user_email'] ?? "Unknown User"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (details.isNotEmpty) const SizedBox(height: 4),
            if (details.isNotEmpty)
              Text(
                details.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '\${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '\${difference.inHours}h ago';
    } else {
      return '\${difference.inDays}d ago';
    }
  }

  Future<void> _clearCache() async {
    try {
      final response = await _backendApiService.clearCache();
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear cache: \${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error clearing cache: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _optimizeDatabase() async {
    try {
      final response = await _backendApiService.optimizeDatabase();
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database optimized successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to optimize database: \${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error optimizing database: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runDiagnostics() async {
    try {
      final response = await _backendApiService.runDiagnostics();
      if (response.isSuccess) {
        final data = response.data;
        final status = data != null && data['status'] != null ? data['status'].toString() : 'Success';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostics completed: \$status'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostics failed: \${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error running diagnostics: \$e'),
            backgroundColor: Colors.red,
          ),
      );
    }
  }

  Future<void> _loadMoreAuditLogs() async {
    if (_isLoadingMoreAuditLogs || !_hasMoreAuditLogs) return;
    await _loadAuditLogs(loadMore: true);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedActionFilter = null;
      _selectedUserFilter = null;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
    _loadAuditLogs();
  }

  Future<void> _exportToCSV() async {
    try {
      final bool hasActiveFilters = _selectedActionFilter != null ||
          _selectedUserFilter != null ||
          _selectedStartDate != null ||
          _selectedEndDate != null ||
          _searchQuery.isNotEmpty;

      final List<dynamic> logsToExport = hasActiveFilters ? _filteredAuditLogs : _auditLogs;

      if (logsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audit logs to export')),
        );
        return;
      }

      // Create CSV data
      final List<List<dynamic>> csvData = [
        ['Timestamp', 'Action', 'User Email', 'User Role', 'Entity Type', 'Entity Name', 'Details'],
      ];

      for (final log in logsToExport) {
        final createdAt = log['created_at'] as String? ?? '';
        final action = log['action'] as String? ?? '';
        final userEmail = log['user_email'] as String? ?? '';
        final userRole = log['user_role'] as String? ?? '';
        final entityType = log['entity_type'] as String? ?? '';
        final entityName = log['entity_name'] as String? ?? '';
        final details = log['details'] as String? ?? '';

        csvData.add([
          createdAt,
          action,
          userEmail,
          userRole,
          entityType,
          entityName,
          details,
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const filePath = '\${directory.path}/audit_logs_\$timestamp.csv';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Show success message
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exported successfully to \$filePath')),
      );

      debugPrint('✅ CSV exported to: \$filePath');

    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export CSV: \$e')),
      );
      debugPrint('❌ Error exporting CSV: \$e');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final bool hasActiveFilters = _selectedActionFilter != null ||
          _selectedUserFilter != null ||
          _selectedStartDate != null ||
          _selectedEndDate != null ||
          _searchQuery.isNotEmpty;

      final List<dynamic> logsToExport = hasActiveFilters ? _filteredAuditLogs : _auditLogs;

      if (logsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audit logs to export')),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Audit Logs Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: \${DateTime.now().toString()}'),
                pw.SizedBox(height: 10),
                pw.Text('Total logs: \${logsToExport.length}'),
                if (hasActiveFilters) pw.Text('Filtered results'),
              ],
            );
          },
        ),
      );

      // Add logs page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            // ignore: deprecated_member_use
            return pw.Table.fromTextArray(
              headers: ['Timestamp', 'Action', 'User', 'Entity', 'Details'],
              data: logsToExport.map((log) {
                final createdAt = log['created_at'] as String? ?? '';
                final action = log['action'] as String? ?? '';
                final userEmail = log['user_email'] as String? ?? '';
                final entityName = log['entity_name'] as String? ?? '';
                final details = log['details'] as String? ?? '';

                return [createdAt, action, userEmail, entityName, details];
              }).toList(),
            );
          },
        ),
      );

      // Save PDF to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const filePath = '\${directory.path}/audit_logs_\$timestamp.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show success message
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully to \$filePath')),
      );

      debugPrint('✅ PDF exported to: \$filePath');

    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export PDF: \$e')),
      );
      debugPrint('❌ Error exporting PDF: \$e');
    }
  }

  Widget _buildBurnDownChart() {
    final s = _selectCurrentSprint();
    final planned = _parseInt(s?['planned_points']) ?? _parseInt(s?['committed_points']) ?? _parseInt(s?['committedPoints']) ?? 0;
    final completed = _parseInt(s?['completed_points']) ?? _parseInt(s?['completedPoints']) ?? 0;
    final start = _parseDate(s?['start_date'] ?? s?['startDate']);
    final end = _parseDate(s?['end_date'] ?? s?['endDate']);
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

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sprint Burn-down Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                            child: Text(
                              burnDownData[index]['day'].toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: burnDownData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['remaining'] as num).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: burnDownData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['ideal'] as num).toDouble());
                    }).toList(),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              const Text('Actual', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 2,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              const Text('Ideal', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformanceRow(Map<String, dynamic> member) {
    final Color qualityColor = member['qualityScore'] >= 90
        ? Colors.green
        : member['qualityScore'] >= 80
            ? Colors.orange
            : Colors.red;

    final IconData trendIcon = member['trend'] == 'up'
        ? Icons.trending_up
        : member['trend'] == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;

    final Color trendColor = member['trend'] == 'up'
        ? Colors.green
        : member['trend'] == 'down'
            ? Colors.red
            : Colors.grey;

    return Column(
      children: [
        Row(
          children: [
            // Team member info
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: member['avatarUrl'] != null
                        ? ClipOval(child: Image.network(member['avatarUrl']))
                        : Text(
                            member['name'].toString().split(' ').map((n) => n[0]).join(),
                            style: const TextStyle(color: Colors.blue),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        member['role'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Points
            Expanded(
              child: Text(
                member['completedPoints'].toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Quality score
            Expanded(
              child: Text(
                '${member['qualityScore']}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: qualityColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Velocity
            Expanded(
              child: Text(
                member['velocity'].toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Cycle time
            Expanded(
              child: Text(
                member['avgCycleTime'],
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            
            // Blocked items
            Expanded(
              child: Text(
                member['blockedItems'].toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: member['blockedItems'] > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Trend indicator
            SizedBox(
              width: 40,
              child: Icon(
                trendIcon,
                color: trendColor,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTeamPerformanceTrendsChart() {
    final List<dynamic> rawTrends = (_analyticsData['performance_trends'] ?? _analyticsData['trends'] ?? []) as List<dynamic>;
    final List<Map<String, dynamic>> trendData = rawTrends.map((t) => (t is Map) ? t.cast<String, dynamic>() : <String, dynamic>{}).where((t) => t.isNotEmpty).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Trends',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (trendData.isEmpty)
            const Center(child: Text('No performance trends data available'))
          else
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < trendData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                (trendData[index]['week'] ?? trendData[index]['label'] ?? '').toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData.asMap().entries.map((entry) {
                        final num points = (entry.value['points'] ?? entry.value['value'] ?? 0) as num;
                        return FlSpot(entry.key.toDouble(), points.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: trendData.asMap().entries.map((entry) {
                        final num quality = (entry.value['quality'] ?? entry.value['score'] ?? 0) as num;
                        return FlSpot(entry.key.toDouble(), quality.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, color: Colors.blue),
              const SizedBox(width: 4),
              const Text('Points Completed', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, color: Colors.green),
              const SizedBox(width: 4),
              const Text('Quality Score', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  void _showTeamPerformanceFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Team Performance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Time Period:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: 'last_30_days',
                items: const [
                  DropdownMenuItem(value: 'last_7_days', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 'last_30_days', child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 'last_90_days', child: Text('Last 90 Days')),
                  DropdownMenuItem(value: 'current_sprint', child: Text('Current Sprint')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              const Text('Metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Points Completed'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Quality Score'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Velocity'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Cycle Time'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
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


