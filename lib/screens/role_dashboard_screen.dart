import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/backend_api_service.dart';
import '../services/api_service.dart';
import '../services/sign_off_report_service.dart';
import '../models/sign_off_report.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';
import '../widgets/sprint_performance_chart.dart';
import '../widgets/background_image.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class RoleDashboardScreen extends ConsumerStatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  ConsumerState<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends ConsumerState<RoleDashboardScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();
  late RealtimeService realtimeService;
  final SignOffReportService _reportService = SignOffReportService(AuthService());
  bool _isLoadingDashboardDeliverables = false;
  bool _isLoadingDashboardSprints = false;
  bool _isLoadingDashboardProjects = false;
  List<Map<String, dynamic>> _dashboardDeliverables = [];
  List<Map<String, dynamic>> _dashboardSprints = [];
  List<Map<String, dynamic>> _dashboardProjects = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _filteredAuditLogs = [];
  final BackendApiService _backendService = BackendApiService();
  final BackendApiService _backendApiService = BackendApiService();
  List<Map<String, dynamic>> _pendingReports = [];
  bool _isLoadingPendingReports = false;
  String? _pendingReportsError;
  Map<String, dynamic> _clientReviewMetrics = {};
  bool _isLoadingClientMetrics = false;
  Map<String, dynamic> _teamMetrics = {};
  bool _isLoadingTeamMetrics = false;
  String _selectedChartType = 'velocity';
  bool _isLoadingAuditLogs = false;
  String? _auditLogsError;
  bool _isLoadingMoreAuditLogs = false;
  int _auditLogsPage = 1;
  final int _auditLogsPerPage = 20;
  bool _hasMoreAuditLogs = true;
  String? _selectedActionFilter;
  String? _selectedUserFilter;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final String _searchQuery = '';
  final String _sortField = 'created_at';
  final bool _sortAscending = false;
  

  @override
  void initState() {
    super.initState();
    realtimeService = RealtimeService();
    realtimeService.initialize(authToken: _authService.accessToken);
    _loadCurrentUser();
    _loadDashboardSprints();
    _loadDashboardDeliverables();
    _loadDashboardProjects();
    _loadReviewHistoryReports();
    _loadPendingReports();
    _loadClientReviewMetrics();
    _computeTeamMetrics();
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
    realtimeService.offAll('project_created');
    realtimeService.offAll('project_updated');
    realtimeService.offAll('notification_received');
    super.dispose();
  }

  Future<void> _loadDashboardSprints() async {
    setState(() => _isLoadingDashboardSprints = true);
    try {
      final items = await ApiService.getSprints();
      _dashboardSprints = items;
      _computeTeamMetrics();
    } finally {
      if (mounted) setState(() => _isLoadingDashboardSprints = false);
    }
  }
  
  Future<void> _loadDashboardDeliverables() async {
    setState(() => _isLoadingDashboardDeliverables = true);
    try {
      final items = await ApiService.getDeliverables();
      _dashboardDeliverables = items;
      _computeTeamMetrics();
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
      _computeTeamMetrics();
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
  

  Future<void> _loadCurrentUser() async {
    try {
      // Initialize AuthService first
      await _authService.initialize();
      
      // Get the current user from AuthService
      final user = await _authService.getCurrentUser();
      if (user != null && (user.isActive || user.isSystemAdmin)) {
        if (!mounted) return;
        setState(() {
          _currentUser = user;
        });
        debugPrint('✅ Loaded user: ${user.name} (${user.email}) - Role: ${user.role}');
        
        // Load audit logs after user is loaded
        _loadAuditLogs();
      } else {
        if (!_authService.isAuthenticated) {
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
            router.go('/');
          }
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
        _auditLogsError = null;
      }
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
        debugPrint('❌ Error loading audit logs: \${_auditLogsError}');
      }
    } catch (e) {
      setState(() {
        _auditLogsError = 'Failed to load audit logs: \$e';
      });
      debugPrint('❌ Exception loading audit logs: \$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAuditLogs = false;
          _isLoadingMoreAuditLogs = false;
        });
      }
    }
  }


  void _applySearchAndSort() {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_auditLogs);
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((Map<String, dynamic> log) {
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
    filtered.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
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


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: BackgroundImage(
        imagePath: 'assets/Icons/khono_bg.png',
        withGlassEffect: false,
        overlayOpacity: 0.25,
        child: _buildRoleSpecificContent(),
      ),
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
          child: FutureBuilder<Uint8List?>(
            future: _loadAvatarBytes(_currentUser!.id),
            builder: (context, snapshot) {
              final hasImage = snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
              return CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: hasImage ? MemoryImage(snapshot.data!) : null,
                child: hasImage
                    ? null
                    : Icon(
                        _currentUser!.roleIcon,
                        color: _currentUser!.roleColor,
                      ),
              );
            },
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
          _buildDeliverablesOverview(),
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
          _buildAdminFeatures(),
          const SizedBox(height: 24),
          _buildReminderQuickActions(),
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
            _buildCardHeader(Icons.notifications_active, 'Approval Reminders', route: '/approval-requests'),
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
      List<dynamic> items = const [];
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        final d = raw['data'];
        if (d is List) {
          items = d;
        } else if (d is Map) {
          final inner = d['reports'] ?? d['items'] ?? d['data'];
          if (inner is List) {
            items = inner;
          } else {
            items = const [];
          }
        } else {
          final r = raw['reports'];
          if (r is List) {
            items = r;
          } else if (r is Map) {
            final inner = r['items'] ?? r['data'];
            if (inner is List) items = inner;
          } else {
            final i = raw['items'];
            if (i is List) items = i;
          }
        }
      }

      final reports = items
          .whereType<Map>()
          .map((e) {
            final m = e.cast<String, dynamic>();
            final c = m['content'];
            if (c is String) {
              try {
                final decoded = jsonDecode(c);
                if (decoded is Map) m['content'] = Map<String, dynamic>.from(decoded);
              } catch (_) {}
            }
            return m;
          })
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
        leading: FutureBuilder<Uint8List?>(
          future: _loadAvatarBytes(_currentUser!.id),
          builder: (context, snapshot) {
            final hasImage = snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
            return CircleAvatar(
              backgroundImage: hasImage ? MemoryImage(snapshot.data!) : null,
              child: hasImage ? null : Icon(_currentUser?.roleIcon ?? Icons.person),
            );
          },
        ),
        title: Text('Welcome, ${_currentUser?.name ?? 'User'}'),
        subtitle: Text('${_currentUser?.roleDisplayName ?? 'Member'} Dashboard'),
      ),
    );
  }

  Future<Uint8List?> _loadAvatarBytes(String userId) async {
    try {
      final base = Uri.parse(ApiService.baseUrl);
      final url = '${base.scheme}://${base.host}:${base.port}/api/v1/profile/$userId/picture?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = await ApiService.getAuthHeaders();
      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _buildQuickActions() {
    final canCreate = _authService.canCreateDeliverable();
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButton(
                icon: Icons.assignment_outlined,
                label: 'Create Deliverable',
                onTap: () => context.go('/deliverable-setup'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButton(
                icon: Icons.flag_outlined,
                label: 'Open Sprint Console',
                onTap: () => context.go('/sprint-console'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (canCreate)
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildActionButton(
                  icon: Icons.description_outlined,
                  label: 'Build Report',
                  onTap: () {
                    final first = _dashboardDeliverables.isNotEmpty ? _dashboardDeliverables.first : null;
                    final id = first != null ? (first['id']?.toString() ?? first['uuid']?.toString() ?? '') : '';
                    if (id.isNotEmpty) context.go('/report-builder/$id');
                  },
                ),
              ),
            ),
          ),
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
                  _buildCardHeader(Icons.assignment_outlined, 'My Deliverables', route: '/repository'),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final uid = _currentUser?.id.toString() ?? '';
                    final my = _dashboardDeliverables.where((d) {
                      final assigned = (d['assigned_to'] ?? d['assignedTo'] ?? '').toString();
                      final created = (d['created_by'] ?? d['createdBy'] ?? '').toString();
                      return assigned == uid || created == uid;
                    }).toList();
                    if (my.isEmpty) {
                      return const Text('No deliverables yet');
                    }
                    return Column(
                      children: my.take(5).map((d) {
                        final title = d['title'] ?? d['name'] ?? d['deliverableName'] ?? 'Untitled Deliverable';
                        final status = (d['status'] ?? d['reviewStatus'] ?? '').toString();
                        final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_turned_in, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _priorityChip((d['priority'] ?? '').toString()),
                                  _dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => _updateDeliverableStatus(id, 'in_progress'),
                                    icon: const Icon(Icons.play_circle_outline, size: 18),
                                    label: const Text('Start'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => _updateDeliverableStatus(id, 'completed'),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Complete'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => context.go('/report-builder/$id'),
                                    icon: const Icon(Icons.description_outlined, size: 18),
                                    label: const Text('Report'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => _editDeliverable(d),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      final route = id.isNotEmpty ? '/report-editor/$id' : '/repository';
                                      context.go(route);
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    tooltip: 'Open',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildDeliverablesOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardDeliverables
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.assignment_outlined, 'Deliverables Overview (${_dashboardDeliverables.length})', route: '/repository'),
                  const SizedBox(height: 8),
                  ..._dashboardDeliverables.take(6).map((d) {
                    final title = d['title'] ?? d['name'] ?? d['deliverableName'] ?? 'Untitled Deliverable';
                    final status = (d['status'] ?? d['reviewStatus'] ?? '').toString();
                    final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _priorityChip((d['priority'] ?? '').toString()),
                              _dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _editDeliverable(d),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _updateDeliverableStatus(id, 'completed'),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Complete'),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  final route = id.isNotEmpty ? '/report-editor/$id' : '/repository';
                                  context.go(route);
                                },
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open',
                              ),
                            ],
                          ),
                        ],
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
                      _buildCardHeader(Icons.history, 'Recent Activity', route: '/notifications'),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final userId = _currentUser?.id.toString() ?? '';
                        final userName = _currentUser?.name ?? '';
                        final my = _filteredAuditLogs.where((a) {
                          final actor = (a['actor'] ?? a['user'] ?? '').toString();
                          final uid = (a['user_id'] ?? a['actor_id'] ?? '').toString();
                          return actor == userName || uid == userId;
                        }).toList();
                        if (my.isEmpty) return const Text('No recent activity');
                        return Column(
                          children: my.take(5).map((a) {
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
                          }).toList(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.group_outlined, 'Team Metrics', route: '/sprint-console'),
            const SizedBox(height: 12),
            if (_isLoadingTeamMetrics)
              const Center(child: CircularProgressIndicator())
            else if (_teamMetrics.isEmpty)
              const Text('No team data available')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricTile('Deliverables', _teamMetrics['deliverables'] ?? 0, Icons.assignment_outlined, Colors.blue),
                  _metricTile('In Progress', _teamMetrics['in_progress'] ?? 0, Icons.play_circle_outline, Colors.orange),
                  _metricTile('Completed', _teamMetrics['completed'] ?? 0, Icons.check_circle_outline, Colors.green),
                  _metricTile('Overdue', _teamMetrics['overdue'] ?? 0, Icons.warning_amber_outlined, Colors.red),
                  _metricTile('Active Sprints', _teamMetrics['active_sprints'] ?? 0, Icons.flag_outlined, Colors.purple),
                  _metricTile('Pending Reviews', _teamMetrics['pending_reviews'] ?? 0, Icons.rule_folder_outlined, Colors.blueGrey),
                  _metricTile('Completion Rate', _teamMetrics['completion_rate'] ?? '-', Icons.pie_chart_outline, Colors.teal),
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
                  _buildCardHeader(Icons.folder_outlined, 'Projects (${_dashboardProjects.length})', route: '/sprint-console'),
                  const SizedBox(height: 8),
                  ..._dashboardProjects.take(5).map((p) {
                    final name = p['name'] ?? p['title'] ?? p['projectName'] ?? 'Untitled Project';
                    final status = p['status'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final projectKey = p['projectKey']?.toString() ?? p['key']?.toString() ?? p['slug']?.toString() ?? '';
                          final route = projectKey.isNotEmpty ? '/sprint-console?projectKey=${Uri.encodeComponent(projectKey)}' : '/sprint-console';
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
        child: _isLoadingPendingReports
            ? const Center(child: CircularProgressIndicator())
            : (_pendingReportsError != null
                ? Text(_pendingReportsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.fact_check_outlined, 'Pending Reviews (${_pendingReports.length})', route: '/approval-requests'),
                      const SizedBox(height: 8),
                      ..._pendingReports.take(5).map((r) {
                        final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                        final createdBy = (r['createdBy'] ?? r['created_by_name'] ?? r['created_by'] ?? '').toString();
                        final id = (r['id'] ?? r['report_id'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (id.isEmpty) return;
                                    final titleText = title.isNotEmpty ? title : 'Sign-Off Report';
                                    final createdByName = createdBy.isNotEmpty ? createdBy : 'Unknown';
                                    final deliverableId = (r['deliverableId']?.toString() ?? r['deliverable_id']?.toString() ?? '').toString();
                                    final report = SignOffReport(
                                      id: id,
                                      deliverableId: deliverableId,
                                      reportTitle: titleText,
                                      reportContent: '',
                                      sprintIds: const [],
                                      status: ReportStatus.submitted,
                                      createdAt: DateTime.now(),
                                      createdBy: createdByName,
                                    );
                                    GoRouter.of(context).push('/client-review/$id', extra: {'report': report});
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(createdBy.isNotEmpty ? '$title • $createdBy' : title)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _approveReport(id),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Approve'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _promptChangeRequest(r),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Request Changes'),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget _buildTeamPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildCardHeader(Icons.insights_outlined, 'Team Performance', route: '/sprint-console')),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedChartType,
                  items: const [
                    DropdownMenuItem(value: 'velocity', child: Text('Velocity')),
                    DropdownMenuItem(value: 'burndown', child: Text('Burndown')),
                    DropdownMenuItem(value: 'burnup', child: Text('Burnup')),
                    DropdownMenuItem(value: 'defects', child: Text('Defects')),
                    DropdownMenuItem(value: 'test_pass_rate', child: Text('Test Pass Rate')),
                  ],
                  onChanged: (v) { if (v != null) setState(() { _selectedChartType = v; }); },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SprintPerformanceChart(sprints: _dashboardSprints, chartType: _selectedChartType),
        const SizedBox(height: 12),
        _teamPerformanceSummary(),
      ],
    );
  }

  Widget _buildReviewMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.rate_review_outlined, 'Review Metrics', route: '/report-repository'),
            const SizedBox(height: 12),
            if (_isLoadingClientMetrics)
              const Center(child: CircularProgressIndicator())
            else if (_clientReviewMetrics.isEmpty)
              const Text('No metrics available')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricTile('Submitted', _clientReviewMetrics['submitted'] ?? 0, Icons.upload_outlined, Colors.orange),
                  _metricTile('Approved', _clientReviewMetrics['approved'] ?? 0, Icons.check_circle_outline, Colors.green),
                  _metricTile('Changes Requested', _clientReviewMetrics['changes'] ?? 0, Icons.edit_note, Colors.blueGrey),
                  _metricTile('Rejected', _clientReviewMetrics['rejected'] ?? 0, Icons.cancel_outlined, Colors.red),
                  _metricTile('Avg Review Time', _clientReviewMetrics['avg_review_time'] ?? '-', Icons.schedule_outlined, Colors.blue),
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
        padding: const EdgeInsets.all(16),
        child: _isLoadingPendingReports
            ? const Center(child: CircularProgressIndicator())
            : (_pendingReportsError != null
                ? Text(_pendingReportsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(Icons.rule_folder_outlined, 'Pending Approvals (${_pendingReports.length})', route: '/report-repository'),
                      const SizedBox(height: 8),
                      ..._pendingReports.take(5).map((r) {
                        final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                        final createdBy = (r['createdBy'] ?? r['created_by_name'] ?? r['created_by'] ?? '').toString();
                        final id = (r['id'] ?? r['report_id'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (id.isNotEmpty) context.go('/client-review/$id');
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.assignment_turned_in_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(createdBy.isNotEmpty ? '$title • $createdBy' : title)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _approveReport(id),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Approve'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => _promptChangeRequest(r),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Request Changes'),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget _buildRecentSubmissions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.upload_outlined, 'Recent Submissions', route: '/report-repository'),
            const SizedBox(height: 8),
            if (_isLoadingPendingReports)
              const Center(child: CircularProgressIndicator())
            else if (_pendingReports.isEmpty)
              const Text('No recent submissions')
            else
              ..._pendingReports.take(5).map((r) {
                final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                final createdAtStr = (r['created_at'] ?? r['createdAt'] ?? r['created'] ?? '').toString();
                String ts = createdAtStr;
                try {
                  final dt = DateTime.tryParse(createdAtStr);
                  if (dt != null) ts = '${dt.toLocal()}';
                } catch (_) {}
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ts.isNotEmpty ? '$title • $ts' : title)),
                    ],
                  ),
                );
              }),
          ],
        ),
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



  

  



  Widget _metricTile(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value is String ? value : value.toString(), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String priority) {
    final p = priority.toLowerCase();
    Color c;
    if (p == 'high') { c = Colors.red; }
    else if (p == 'medium') { c = Colors.orange; }
    else if (p == 'low') { c = Colors.green; }
    else { c = Colors.blueGrey; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 14),
          const SizedBox(width: 4),
          Text(p.isNotEmpty ? p : 'priority'),
        ],
      ),
    );
  }

  Widget _dueDateChip(dynamic dueRaw) {
    String label = '';
    if (dueRaw != null) {
      final s = dueRaw.toString();
      final dt = DateTime.tryParse(s);
      if (dt != null) { label = dt.toLocal().toString(); }
      else { label = s; }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, size: 14),
          const SizedBox(width: 4),
          Text(label.isNotEmpty ? label : 'due date'),
        ],
      ),
    );
  }

  Future<void> _editDeliverable(Map<String, dynamic> d) async {
    final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
    if (id.isEmpty) return;
    final titleController = TextEditingController(text: (d['title'] ?? d['name'] ?? '').toString());
    final descriptionController = TextEditingController(text: (d['description'] ?? '').toString());
    final dodController = TextEditingController(text: (d['definition_of_done'] ?? d['definitionOfDone'] ?? '').toString());
    String priority = (d['priority'] ?? '').toString().toLowerCase();
    final dueController = TextEditingController(text: (d['due_date'] ?? d['dueDate'] ?? d['deadline'] ?? '').toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Deliverable'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: dodController, maxLines: 2, decoration: const InputDecoration(labelText: 'Definition of Done', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority.isNotEmpty ? priority : null,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (v) { if (v != null) priority = v; },
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dueController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = dueController.text.isNotEmpty ? (DateTime.tryParse(dueController.text) ?? now) : now;
                    final date = await showDatePicker(context: context, initialDate: initial, firstDate: now.subtract(const Duration(days: 365)), lastDate: now.add(const Duration(days: 365 * 3)),);
                    if (date != null) dueController.text = date.toIso8601String();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => context.pop(true), child: const Text('Save')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final updates = <String, dynamic>{};
    if (titleController.text.trim().isNotEmpty) updates['title'] = titleController.text.trim();
    if (descriptionController.text.trim().isNotEmpty) updates['description'] = descriptionController.text.trim();
    if (dodController.text.trim().isNotEmpty) updates['definition_of_done'] = dodController.text.trim();
    if (priority.isNotEmpty) updates['priority'] = priority;
    if (dueController.text.trim().isNotEmpty) updates['due_date'] = dueController.text.trim();
    if (updates.isEmpty) return;
    final resp = await _backendService.updateDeliverable(id, updates);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (resp.isSuccess) {
      setState(() {
        _dashboardDeliverables = _dashboardDeliverables.map((e) {
          final eId = (e['id']?.toString() ?? e['uuid']?.toString() ?? '');
          if (eId == id) {
            final m = Map<String, dynamic>.from(e);
            updates.forEach((k, v) { m[k] = v; });
            return m;
          }
          return e;
        }).toList();
      });
      messenger.showSnackBar(const SnackBar(content: Text('Deliverable updated')));
      _computeTeamMetrics();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to update deliverable')));
    }
  }

  Future<void> _updateDeliverableStatus(String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.updateDeliverableStatus(id: id, status: status);
      setState(() {
        _dashboardDeliverables = _dashboardDeliverables.map((d) {
          final dId = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
          if (dId == id) {
            final m = Map<String, dynamic>.from(d);
            m['status'] = status;
            return m;
          }
          return d;
        }).toList();
      });
      messenger.showSnackBar(SnackBar(content: Text('Status updated to $status')));
      _computeTeamMetrics();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void _computeTeamMetrics() {
    if (!mounted) return;
    setState(() => _isLoadingTeamMetrics = true);
    try {
      final int totalDeliverables = _dashboardDeliverables.length;
      int completed = 0;
      int inProgress = 0;
      int overdue = 0;
      for (final d in _dashboardDeliverables) {
        final status = (d['status'] ?? d['state'] ?? '').toString().toLowerCase();
        if (status == 'completed' || status == 'done' || status == 'approved') completed++;
        if (status == 'in_progress' || status == 'in-progress' || status == 'progress') inProgress++;
        final dueStr = (d['due_date'] ?? d['dueDate'] ?? d['deadline'] ?? '').toString();
        final due = DateTime.tryParse(dueStr);
        if (due != null && due.isBefore(DateTime.now()) && status != 'completed' && status != 'done' && status != 'approved') {
          overdue++;
        }
      }
      int activeSprints = 0;
      for (final s in _dashboardSprints) {
        final status = (s['status'] ?? s['state'] ?? '').toString().toLowerCase();
        if (status == 'active' || status == 'in_progress' || status == 'in-progress') activeSprints++;
      }
      final pendingReviews = _pendingReports.length;
      String completionRateStr;
      if (totalDeliverables > 0) {
        final rate = (completed / totalDeliverables * 100).toStringAsFixed(1);
        completionRateStr = '$rate%';
      } else {
        completionRateStr = '-';
      }
      final m = <String, dynamic>{
        'deliverables': totalDeliverables,
        'completed': completed,
        'in_progress': inProgress,
        'overdue': overdue,
        'active_sprints': activeSprints,
        'pending_reviews': pendingReviews,
        'completion_rate': completionRateStr,
      };
      if (mounted) {
        setState(() {
          _teamMetrics = m;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _teamMetrics = {});
    } finally {
      if (mounted) setState(() => _isLoadingTeamMetrics = false);
    }
  }

  Future<void> _loadPendingReports() async {
    setState(() {
      _isLoadingPendingReports = true;
      _pendingReportsError = null;
    });
    try {
      final resp = await _reportService.getSignOffReports(status: 'submitted');
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> items = const [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          final d = raw['data'];
          if (d is List) {
            items = d;
          } else if (d is Map) {
            final inner = d['reports'] ?? d['items'] ?? d['data'];
            if (inner is List) {
              items = inner;
            }
          } else {
            final r = raw['reports'];
            if (r is List) {
              items = r;
            } else if (r is Map) {
              final inner = r['items'] ?? r['data'];
              if (inner is List) items = inner;
            } else {
              final i = raw['items'];
              if (i is List) items = i;
            }
          }
        }
        setState(() {
          final parsed = items.whereType<Map>().map((e) {
            final m = e.cast<String, dynamic>();
            final c = m['content'];
            if (c is String) {
              try {
                final decoded = jsonDecode(c);
                if (decoded is Map) m['content'] = Map<String, dynamic>.from(decoded);
              } catch (_) {}
            }
            return m;
          });
          _pendingReports = parsed.where((m) {
            final content = m['content'];
            final statusRaw = (m['status'] ?? m['review_status'] ?? (content is Map ? content['status'] : null) ?? '').toString().toLowerCase();
            if (statusRaw.isEmpty) return true; // Default to include when unknown
            return statusRaw == 'submitted' || statusRaw == 'under_review' || statusRaw == 'underreview';
          }).toList();
        });
        _computeTeamMetrics();
      } else {
        setState(() {
          _pendingReports = [];
          _pendingReportsError = resp.error ?? 'Failed to load pending reports';
        });
      }
    } catch (_) {
      setState(() {
        _pendingReports = [];
        _pendingReportsError = 'Failed to load pending reports';
      });
    } finally {
      if (mounted) setState(() => _isLoadingPendingReports = false);
    }
  }

  Future<void> _loadClientReviewMetrics() async {
    setState(() {
      _isLoadingClientMetrics = true;
    });
    try {
      final resp = await _reportService.getSignOffReports();
      final m = {
        'submitted': 0,
        'approved': 0,
        'changes': 0,
        'rejected': 0,
        'avg_review_time': '-',
      };
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> items = const [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          final d = raw['data'];
          if (d is List) {
            items = d;
          } else if (d is Map) {
            final inner = d['reports'] ?? d['items'] ?? d['data'];
            if (inner is List) {
              items = inner;
            } else {
              items = const [];
            }
          } else {
            final r = raw['reports'];
            if (r is List) {
              items = r;
            } else if (r is Map) {
              final inner = r['items'] ?? r['data'];
              if (inner is List) items = inner;
            } else {
              final i = raw['items'];
              if (i is List) items = i;
            }
          }
        }
        int submitted = 0;
        int approved = 0;
        int changes = 0;
        int rejected = 0;
        final durations = <double>[];
        for (final r in items.whereType<Map>()) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          if (s == 'submitted') submitted++;
          if (s == 'approved') approved++;
          if (s.contains('change')) changes++;
          if (s == 'rejected' || s == 'declined') rejected++;
          final createdStr = (r['created_at'] ?? r['createdAt'] ?? '').toString();
          final approvedStr = (r['approved_at'] ?? r['approvedAt'] ?? r['reviewed_at'] ?? '').toString();
          final created = DateTime.tryParse(createdStr);
          final approvedDt = DateTime.tryParse(approvedStr);
          if (created != null && approvedDt != null && approvedDt.isAfter(created)) {
            final hours = approvedDt.difference(created).inMinutes / 60.0;
            durations.add(hours);
          }
        }
        m['submitted'] = submitted;
        m['approved'] = approved;
        m['changes'] = changes;
        m['rejected'] = rejected;
        if (durations.isNotEmpty) {
          final avg = durations.reduce((a, b) => a + b) / durations.length;
          m['avg_review_time'] = '${avg.toStringAsFixed(1)}h';
        }
      }
      setState(() {
        _clientReviewMetrics = m;
      });
    } catch (_) {
      setState(() {
        _clientReviewMetrics = {};
      });
    } finally {
      if (mounted) setState(() => _isLoadingClientMetrics = false);
    }
  }

  Widget _teamPerformanceSummary() {
    double planned = 0;
    double completed = 0;
    double defects = 0;
    for (final s in _dashboardSprints) {
      final p = s['planned_points'] ?? s['planned'] ?? 0;
      final c = s['completed_points'] ?? s['completed'] ?? 0;
      final d = s['defects_opened'] ?? s['defect_count'] ?? 0;
      planned += (p is num) ? p.toDouble() : double.tryParse(p.toString()) ?? 0;
      completed += (c is num) ? c.toDouble() : double.tryParse(c.toString()) ?? 0;
      defects += (d is num) ? d.toDouble() : double.tryParse(d.toString()) ?? 0;
    }
    final avgVelocity = _dashboardSprints.isNotEmpty ? (completed / _dashboardSprints.length) : 0;
    final carryover = planned - completed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metricTile('Avg Velocity', avgVelocity.toStringAsFixed(1), Icons.speed, Colors.blue),
          _metricTile('Planned', planned.toStringAsFixed(1), Icons.trending_up, Colors.orange),
          _metricTile('Completed', completed.toStringAsFixed(1), Icons.check_circle_outline, Colors.green),
          _metricTile('Carryover', carryover.toStringAsFixed(1), Icons.sync_problem, Colors.red),
          _metricTile('Defects', defects.toStringAsFixed(0), Icons.bug_report, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildAdminFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.settings_applications, 'Admin Features', route: '/settings'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _featureTile(Icons.dashboard_outlined, 'System Metrics', () => context.go('/system-metrics')),
                _featureTile(Icons.security, 'Role Management', () => context.go('/role-management')),
                _featureTile(Icons.health_and_safety, 'System Health', () => context.go('/system-health')),
                _featureTile(Icons.receipt_long, 'Audit Logs', () => context.go('/audit-logs')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> _approveReport(String reportId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _reportService.approveReport(reportId);
      if (resp.isSuccess) {
        setState(() {
          _pendingReports = _pendingReports.where((e) => (e['id']?.toString() ?? e['report_id']?.toString() ?? '') != reportId).toList();
        });
        await _notifyReportSender(reportId, approved: true);
        messenger.showSnackBar(const SnackBar(content: Text('Report approved')));
        _loadClientReviewMetrics();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to approve report')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _requestChanges(String reportId, String details) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _reportService.requestChanges(reportId, details);
      if (resp.isSuccess) {
        setState(() {
          _pendingReports = _pendingReports.where((e) => (e['id']?.toString() ?? e['report_id']?.toString() ?? '') != reportId).toList();
        });
        await _notifyReportSender(reportId, approved: false, details: details);
        messenger.showSnackBar(const SnackBar(content: Text('Change request sent')));
        _loadClientReviewMetrics();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to request changes')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _notifyReportSender(String reportId, {required bool approved, String? details}) async {
    try {
      final token = _authService.accessToken;
      final ns = NotificationService();
      if (token != null) ns.setAuthToken(token);
      final resp = await _backendService.getSignOffReport(reportId);
      String title = approved ? 'Report Approved' : 'Report Changes Requested';
      String message = approved ? '${_currentUser?.name ?? 'Reviewer'} approved "Report"' : '${_currentUser?.name ?? 'Reviewer'} requested changes on "Report"';
      String? targetUserId;
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        Map<String, dynamic> m = {};
        if (raw is Map<String, dynamic>) {
          final d = raw['data'];
          if (d is Map<String, dynamic>) {
            m = d;
          } else {
            m = raw;
          }
        }
        final content = m['content'];
        final String reportTitle = (m['reportTitle'] ?? m['report_title'] ?? (content is Map ? (content['reportTitle'] ?? content['title']) : null) ?? m['title'] ?? 'Report').toString();
        title = approved ? 'Report Approved' : 'Report Changes Requested';
        message = approved ? '${_currentUser?.name ?? 'Reviewer'} approved "$reportTitle"' : '${_currentUser?.name ?? 'Reviewer'} requested changes for "$reportTitle"';
        final createdByRaw = (m['createdBy'] ?? m['created_by'] ?? '').toString();
        final createdByName = (m['createdByName'] ?? m['created_by_name'] ?? '').toString();
        if (createdByRaw.isNotEmpty) {
          final isUuidLike = RegExp(r'^[a-f0-9-]{8,}$', caseSensitive: false).hasMatch(createdByRaw);
          final looksLikeEmail = createdByRaw.contains('@');
          final hasSpaces = createdByRaw.contains(' ');
          if (isUuidLike && !looksLikeEmail && !hasSpaces) {
            targetUserId = createdByRaw;
          }
        }
        if (targetUserId == null && createdByName.isNotEmpty) {
          try {
            final usersResp = await _backendService.getUsers(page: 1, limit: 200);
            final rawUsers = usersResp.isSuccess ? usersResp.data : null;
            final List<dynamic> items = rawUsers is List
                ? rawUsers
                : (rawUsers is Map<String, dynamic> ? (rawUsers['data'] ?? rawUsers['users'] ?? rawUsers['items'] ?? []) : []);
            for (final u in items) {
              if (u is Map) {
                final um = Map<String, dynamic>.from(u);
                final name = (um['name'] ?? '').toString();
                final first = (um['first_name'] ?? um['firstName'] ?? '').toString();
                final last = (um['last_name'] ?? um['lastName'] ?? '').toString();
                final combined = ('$first $last').trim();
                if (name.toLowerCase() == createdByName.toLowerCase() || (combined.isNotEmpty && combined.toLowerCase() == createdByName.toLowerCase())) {
                  targetUserId = (um['id'] ?? '').toString();
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }
      await ns.createNotification(title: title, message: message, type: approved ? NotificationType.reportApproved : NotificationType.reportChangesRequested, userId: targetUserId);
      try {
        final event = approved ? 'report_approved' : 'report_change_requested';
        realtimeService.emit(event, {'reportId': reportId});
        realtimeService.emit('approval_updated', {'reportId': reportId});
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _promptChangeRequest(Map<String, dynamic> report) async {
    final id = (report['id'] ?? report['report_id'] ?? '').toString();
    if (id.isEmpty) return;
    String details = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Changes'),
          content: TextField(
            onChanged: (v) => details = v,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Details'),
            maxLines: 4,
          ),
          actions: [
            TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => context.pop(true), child: const Text('Send')),
          ],
        );
      },
    );
    if (confirmed == true && details.trim().isNotEmpty) {
      await _requestChanges(id, details.trim());
    }
  }

  Widget _buildDeveloperDashboard() => _buildTeamMemberDashboard();
  Widget _buildProjectManagerDashboard() => _buildDeliveryLeadDashboard();
  Widget _buildScrumMasterDashboard() => _buildDeliveryLeadDashboard();
  Widget _buildQAEngineerDashboard() => _buildTeamMemberDashboard();
  Widget _buildStakeholderDashboard() => _buildClientReviewerDashboard();

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: _currentUser?.isSystemAdmin == true ? Theme.of(context).colorScheme.primary : null,
      ),
      label: Text(label),
    );
  }

  Widget _buildCardHeader(IconData icon, String label, {String? route}) {
    final row = Row(
      children: [
        Icon(
          icon,
          color: _currentUser?.isSystemAdmin == true
              ? Theme.of(context).colorScheme.secondary
              : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
    if (route == null) return row;
    return InkWell(onTap: () => context.go(route), child: row);
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
    realtimeService.on('approval_created', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('approval_updated', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_submitted', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_approved', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_change_requested', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('project_created', (_) => _loadDashboardProjects());
    realtimeService.on('project_updated', (_) => _loadDashboardProjects());
    realtimeService.on('notification_received', (data) {
      try {
        final type = (data['type'] ?? '').toString();
        if (type == 'project') {
          _loadDashboardProjects();
        } else if (type == 'sprint') {
          _loadDashboardSprints();
        } else if (type == 'deliverable' || type == 'approval' || type == 'change_request') {
          _loadDashboardDeliverables();
          _loadPendingReports();
          _loadClientReviewMetrics();
        }
      } catch (_) {}
    });
  }

  void _handleRoleChanged(dynamic _) {
    _loadCurrentUser();
  }
  

}
