import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/flownet_theme.dart';
import '../models/approval_request.dart';
import '../services/auth_service.dart';
import '../services/approval_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/metrics_card.dart';
import '../widgets/background_image.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final AuthService _authService = AuthService();
  late final ApprovalService _approvalService;
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ApprovalRequest> _requests = [];
  DashboardStats? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _approvalService = ApprovalService(_authService);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final approvalsResponse = await _approvalService.getApprovalRequests();
      final dashboardResponse = await _dashboardService.getDashboardData();

      if (approvalsResponse.isSuccess && approvalsResponse.data != null) {
        setState(() {
          _requests =
              (approvalsResponse.data!['requests'] as List<dynamic>).cast<ApprovalRequest>();
        });
      } else {
        setState(() {
          _errorMessage =
              approvalsResponse.error ?? 'Failed to load approval data for dashboard';
        });
      }

      if (dashboardResponse.isSuccess && dashboardResponse.data != null) {
        final dashboard = dashboardResponse.data!['dashboard'] as DashboardData;
        setState(() {
          _dashboardStats = dashboard.stats;
        });
      } else {
        setState(() {
          _errorMessage = _errorMessage ??
              (dashboardResponse.error ?? 'Failed to load dashboard stats');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final rawName = currentUser?.name ?? '';
    final firstName = rawName.contains(' ')
        ? rawName.split(' ').first
        : rawName;

    final total = _requests.length;
    final pending = _requests.where((r) => r.isPending).length;
    final approved = _requests.where((r) => r.isApproved).length;
    final rejected = _requests.where((r) => r.isRejected).length;

    final recentRequests = _requests.take(5).toList();

    final stats = _dashboardStats;

    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          currentUser != null
              ? '${currentUser.roleDisplayName} dashboard'
              : 'Dashboard',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BackgroundImage(
        withGlassEffect: false,
        overlayOpacity: 0.5,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentUser != null) ...[
                    _buildWelcomeSection(firstName, currentUser.roleDescription),
                    const SizedBox(height: 24),
                  ],
                  _buildMetricsRow(total, pending, approved, rejected, stats),
                  const SizedBox(height: 24),
                  if (stats != null) _buildDeliverableStatsRow(stats),
                  const SizedBox(height: 24),
                  if (stats != null) ...[
                    _buildSignoffTimeRow(stats),
                    const SizedBox(height: 24),
                  ],
                  _buildQuickLinks(context),
                  const SizedBox(height: 24),
                  _buildContentSection(recentRequests),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String firstName, String roleDescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $firstName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: FlownetColors.pureWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          roleDescription,
          style: const TextStyle(
            fontSize: 14,
            color: FlownetColors.coolGray,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverableStatsRow(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final crossAxisCount = isWide ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricsCard(
              title: 'Total deliverables',
              value: stats.totalDeliverables.toString(),
              icon: Icons.inventory_2_outlined,
              color: FlownetColors.electricBlue,
              onTap: () {},
            ),
            MetricsCard(
              title: 'In progress',
              value: stats.inProgressDeliverables.toString(),
              icon: Icons.pending_actions_outlined,
              color: FlownetColors.amberOrange,
              onTap: () {},
            ),
            MetricsCard(
              title: 'Completed',
              value: stats.completedDeliverables.toString(),
              icon: Icons.task_alt_outlined,
              color: FlownetColors.emeraldGreen,
              onTap: () {},
            ),
            MetricsCard(
              title: 'Pending',
              value: stats.pendingDeliverables.toString(),
              icon: Icons.hourglass_empty_outlined,
              color: FlownetColors.coolGray,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignoffTimeRow(DashboardStats stats) {
    return MetricsCard(
      title: 'Avg sign‑off time',
      value: stats.avgSignoffDaysDisplay,
      icon: Icons.schedule_outlined,
      color: FlownetColors.electricBlue,
      onTap: () {},
    );
  }

  Widget _buildMetricsRow(
    int total,
    int pending,
    int approved,
    int rejected,
    DashboardStats? stats,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(FlownetColors.crimsonRed),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: FlownetColors.crimsonRed,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final crossAxisCount = isWide ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricsCard(
              title: 'Total requests',
              value: total.toString(),
              icon: Icons.all_inbox_outlined,
              color: FlownetColors.electricBlue,
              onTap: () {},
            ),
            MetricsCard(
              title: 'Pending approval',
              value: pending.toString(),
              icon: Icons.hourglass_top_outlined,
              color: FlownetColors.amberOrange,
              onTap: () {},
            ),
            MetricsCard(
              title: 'Approved',
              value: approved.toString(),
              icon: Icons.check_circle_outlined,
              color: FlownetColors.emeraldGreen,
              onTap: () {},
            ),
            MetricsCard(
              title: 'Rejected',
              value: rejected.toString(),
              icon: Icons.cancel_outlined,
              color: FlownetColors.crimsonRed,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final canCreateDeliverable = _authService.canCreateDeliverable();
    final canApproveDeliverable =
        _authService.canApproveDeliverable() || _authService.isDeliveryLead;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick links',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FlownetColors.pureWhite,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (canCreateDeliverable)
                  _buildQuickLinkChip(
                    icon: Icons.add_task_outlined,
                    label: 'New deliverable',
                    onTap: () => context.go('/deliverable-setup'),
                  ),
                if (canApproveDeliverable)
                  _buildQuickLinkChip(
                    icon: Icons.assignment_outlined,
                    label: 'Approval requests',
                    onTap: () => context.go('/approvals'),
                  ),
                _buildQuickLinkChip(
                  icon: Icons.folder_outlined,
                  label: 'Repository',
                  onTap: () => context.go('/repository'),
                ),
                _buildQuickLinkChip(
                  icon: Icons.timer_outlined,
                  label: 'Sprint console',
                  onTap: () => context.go('/sprint-console'),
                ),
                _buildQuickLinkChip(
                  icon: Icons.assessment_outlined,
                  label: 'Reports',
                  onTap: () => context.go('/report-repository'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinkChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: FlownetColors.surfaceLight.withAlpha(80),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: FlownetColors.pureWhite),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: FlownetColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(List<ApprovalRequest> recentRequests) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent approval activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FlownetColors.pureWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlownetColors.crimsonRed,
                  ),
                ),
              )
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: FlownetColors.crimsonRed,
                ),
              )
            else if (recentRequests.isEmpty)
              const Text(
                'No recent approval requests.',
                style: TextStyle(
                  color: FlownetColors.coolGray,
                ),
              )
            else
              Column(
                children: recentRequests
                    .map((r) => _buildRequestRow(r))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestRow(ApprovalRequest request) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: const TextStyle(
                    color: FlownetColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.requestedByName,
                  style: const TextStyle(
                    color: FlownetColors.coolGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(request),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ApprovalRequest request) {
    Color color;
    switch (request.status.toLowerCase()) {
      case 'approved':
        color = FlownetColors.emeraldGreen;
        break;
      case 'rejected':
        color = FlownetColors.crimsonRed;
        break;
      default:
        color = FlownetColors.amberOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        request.statusDisplay,
        style: const TextStyle(
          color: FlownetColors.pureWhite,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}