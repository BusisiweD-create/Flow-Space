import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/sign_off_report.dart';
import '../services/backend_api_service.dart';
import '../services/api_client.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/role_guard.dart';

class ReportRepositoryScreen extends ConsumerStatefulWidget {
  const ReportRepositoryScreen({super.key});

  @override
  ConsumerState<ReportRepositoryScreen> createState() => _ReportRepositoryScreenState();
}

class _ReportRepositoryScreenState extends ConsumerState<ReportRepositoryScreen> {
  List<SignOffReport> _reports = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final backendService = BackendApiService();
      final response = await backendService.getSignOffReports();
      
      if (response.isSuccess) {
        final reports = backendService.parseSignOffReportsFromResponse(response);
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      } else {
        // Handle API error gracefully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load reports: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
          _reports = []; // Empty array instead of mock data
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load reports. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        _reports = []; // Empty array instead of mock data
      });
    }
  }

  List<SignOffReport> get _filteredReports {
    var filtered = _reports;

    // Apply status filter
    if (_selectedFilter != 'all') {
      final status = ReportStatus.values.firstWhere(
        (e) => e.name == _selectedFilter,
        orElse: () => ReportStatus.draft,
      );
      filtered = filtered.where((report) => report.status == status).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((report) =>
          report.reportTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.createdBy.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.deliverableId.toLowerCase().contains(_searchQuery.toLowerCase()),
      ).toList();
    }

    return filtered;
  }

  void _showReportDetails(SignOffReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: Text(report.reportTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Status', report.statusDisplayName, report.statusColor),
                _buildDetailRow('Created By', report.createdBy),
                _buildDetailRow('Created At', _formatDate(report.createdAt)),
                if (report.submittedAt != null)
                  _buildDetailRow('Submitted At', _formatDate(report.submittedAt!)),
                if (report.reviewedAt != null)
                  _buildDetailRow('Reviewed At', _formatDate(report.reviewedAt!)),
                if (report.approvedAt != null)
                  _buildDetailRow('Approved At', _formatDate(report.approvedAt!)),
                if (report.clientComment != null) ...[
                  const SizedBox(height: 8),
                  const Text('Client Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(report.clientComment!),
                ],
                if (report.changeRequestDetails != null) ...[
                  const SizedBox(height: 8),
                  const Text('Change Request:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(report.changeRequestDetails!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _confirmDeleteReport(report);
              navigator.pop();
            },
            child: const Text('Delete'),
          ),
          if (report.status == ReportStatus.draft)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to edit report
              },
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FlownetColors.charcoalBlack,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
      ),
      floatingActionButton: RoleBuilder(
        allowedRoles: const ['deliveryLead', 'systemAdmin'],
        builder: (context) => FloatingActionButton.extended(
          onPressed: _showCreateReportDialog,
          icon: const Icon(Icons.add),
          label: const Text('New Sign-Off'),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('draft', 'Draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('submitted', 'Submitted'),
                      const SizedBox(width: 8),
                      _buildFilterChip('underReview', 'Under Review'),
                      const SizedBox(width: 8),
                      _buildFilterChip('approved', 'Approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('changeRequested', 'Change Requested'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(
                    child: Text(
                      'No reports found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: FlownetColors.slate,
      selectedColor: FlownetColors.electricBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }

  Widget _buildReportCard(SignOffReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: FlownetColors.graphiteGray,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.reportTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: report.statusColor),
                    ),
                    child: Text(
                      report.statusDisplayName,
                      style: TextStyle(
                        color: report.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _confirmDeleteReport(report);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      report.createdBy,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      _formatDate(report.createdAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sprint IDs
              if (report.sprintIds.isNotEmpty)
                _buildInfoItem(
                  Icons.timeline,
                  'Sprints: ${report.sprintIds.join(', ')}',
                ),

              // Digital Signature indicator
              if (report.digitalSignature != null) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Digitally Signed',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReport(SignOffReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "${report.reportTitle}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = BackendApiService();
    final response = await api.deleteSignOffReport(report.id);
    if (response.isSuccess) {
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
      _loadReports();
    } else {
      messenger.showSnackBar(SnackBar(content: Text('Failed to delete: ${response.error ?? 'Unknown error'}')));
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showCreateReportDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        final api = BackendApiService();
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Create Sign-Off Report'),
          content: SizedBox(
            width: 450,
            child: FutureBuilder(
              future: api.getDeliverables(page: 1, limit: 50),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final response = snapshot.data as ApiResponse;
                final items = api.parseDeliverablesFromResponse(response);

                if (items.isEmpty) {
                  return const Text('No deliverables available');
                }

                return SizedBox(
                  height: 400,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = items[index];
                      return ListTile(
                        leading: Icon(Icons.assignment, color: d.statusColor),
                        title: Text(d.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Due ${_formatDate(d.dueDate)} · ${d.statusDisplayName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          this.context.go('/report-builder/${d.id}');
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
