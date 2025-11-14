import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/approval_request.dart';
import '../services/backend_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  List<ApprovalRequest> _approvalRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _autoRemindersTriggered = false;

  @override
  void initState() {
    super.initState();
    _loadApprovalRequests();
  }

  Future<void> _loadApprovalRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = BackendApiService();
      final response = await apiService.getApprovalRequests();

      if (response.isSuccess) {
        final dynamic raw = response.data;
        final List<dynamic> approvalData = raw is List
            ? raw
            : (raw is Map<String, dynamic>
                ? (raw['data'] ?? raw['items'] ?? raw['approvals'] ?? [])
                : []);
        final List<ApprovalRequest> approvals = approvalData
            .whereType<Map>()
            .map((data) => ApprovalRequest.fromJson(Map<String, dynamic>.from(data)))
            .toList();

        setState(() {
          _approvalRequests = approvals;
          _isLoading = false;
        });
        await _maybeTriggerAutoReminders();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Failed to load approval requests';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading approval requests: $e';
      });
    }
  }

  Future<void> _maybeTriggerAutoReminders() async {
    final auth = AuthService();
    if (!(auth.isSystemAdmin || auth.isDeliveryLead || auth.isClientReviewer)) return;
    if (_autoRemindersTriggered) return;
    final now = DateTime.now();
    final toRemind = _approvalRequests.where((r) => r.status == ApprovalStatus.pending && now.difference(r.requestedAt).inDays >= 3).toList();
    if (toRemind.isEmpty) {
      _autoRemindersTriggered = true;
      return;
    }
    for (final r in toRemind) {
      await _sendReminder(r.id, silent: true);
    }
    _autoRemindersTriggered = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendForApprovalDialog,
        label: const Text('Send For Approval'),
        icon: const Icon(Icons.send),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search approval requests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Loading and error states
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApprovalRequests,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_approvalRequests.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No approval requests found',
                  style: TextStyle(
                    color: FlownetColors.coolGray,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            // Approval requests list
            Expanded(
              child: ListView.builder(
                itemCount: _approvalRequests.length,
                itemBuilder: (context, index) {
                  final request = _approvalRequests[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(
                      request.deliverableTitle.isNotEmpty ? request.deliverableTitle : 'Untitled Deliverable',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Requested by: ${request.requesterName.isNotEmpty ? request.requesterName : 'Unknown'}'),
                        Text('Date: ${_formatDate(request.requestedAt)}'),
                        if (request.comments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              request.comments,
                              style: const TextStyle(
                                color: FlownetColors.coolGray,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2,),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.status.name.toUpperCase(),
                            style: const TextStyle(
                              color: FlownetColors.pureWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: request.status == ApprovalStatus.pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                    IconButton(
                      icon: const Icon(Icons.check,
                          color: FlownetColors.emeraldGreen,),
                      onPressed: () => _approveRequest(request.id),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: FlownetColors.crimsonRed,),
                      onPressed: () => _denyRequest(request.id),
                      tooltip: 'Reject',
                    ),
                              if (AuthService().isSystemAdmin || AuthService().isDeliveryLead || AuthService().isClientReviewer)
                                IconButton(
                                  icon: const Icon(Icons.notifications_active,
                                      color: FlownetColors.electricBlue,),
                                  onPressed: () => _sendReminder(request.id),
                                  tooltip: 'Send Reminder',
                                ),
                            ],
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return FlownetColors.amberOrange;
      case ApprovalStatus.approved:
        return FlownetColors.emeraldGreen;
      case ApprovalStatus.rejected:
        return FlownetColors.crimsonRed;
      case ApprovalStatus.reminder_sent:
        return FlownetColors.electricBlue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveRequest(String id) async {
    final commentController = TextEditingController();
    final auth = AuthService();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Approve Request'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Approval comment',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiService = BackendApiService();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final response = await apiService.approveRequest(id, {
                  'approved_by': auth.currentUser?.id,
                  'comments': commentController.text.trim(),
                });
                navigator.pop();
                if (response.isSuccess) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Request approved successfully'),
                      backgroundColor: FlownetColors.emeraldGreen,
                    ),
                  );
                  _loadApprovalRequests();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to approve request: ${response.error ?? 'Unknown error'}'),
                      backgroundColor: FlownetColors.crimsonRed,
                    ),
                  );
                }
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _denyRequest(String id) async {
    final commentController = TextEditingController();
    final auth = AuthService();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Reject Request'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Rejection comment',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiService = BackendApiService();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final response = await apiService.rejectRequest(id, {
                  'approved_by': auth.currentUser?.id,
                  'comments': commentController.text.trim(),
                });
                navigator.pop();
                if (response.isSuccess) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Request rejected successfully'),
                      backgroundColor: FlownetColors.crimsonRed,
                    ),
                  );
                  _loadApprovalRequests();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject request: ${response.error ?? 'Unknown error'}'),
                      backgroundColor: FlownetColors.crimsonRed,
                    ),
                  );
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendReminder(String id, {bool silent = false}) async {
    try {
      final apiService = BackendApiService();
      final response = await apiService.sendReminder(id);
      if (!mounted) return;

      if (response.statusCode == 200) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder sent successfully'),
              backgroundColor: FlownetColors.electricBlue,
            ),
          );
        }
        _loadApprovalRequests();
      } else {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reminder: ${response.data?['message'] ?? 'Unknown error'}'),
              backgroundColor: FlownetColors.crimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminder: $e'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Filter Approvals'),
        content: const Text('Filter options would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSendForApprovalDialog() async {
    final deliverables = await ApiService.getDeliverables();
    String? selectedDeliverableId = deliverables.isNotEmpty ? (deliverables.first['id']?.toString()) : null;
    String sendTo = 'client';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Send For Approval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDeliverableId,
                items: deliverables.map((d) {
                  final id = d['id']?.toString() ?? '';
                  final title = d['title']?.toString() ?? 'Untitled';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (v) {
                  selectedDeliverableId = v;
                },
                decoration: const InputDecoration(labelText: 'Deliverable'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: sendTo,
                items: const [
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                  DropdownMenuItem(value: 'system_admin', child: Text('System Admin')),
                ],
                onChanged: (v) {
                  sendTo = v ?? 'client';
                },
                decoration: const InputDecoration(labelText: 'Send To'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDeliverableId == null || selectedDeliverableId!.isEmpty) return;
                final api = BackendApiService();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final response = await api.createApprovalRequest({
                  'deliverable_id': selectedDeliverableId,
                  'send_to': sendTo,
                });
                navigator.pop();
                if (response.isSuccess) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Approval request sent')),
                  );
                  _loadApprovalRequests();
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to send: ${response.error ?? 'Unknown error'}')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
