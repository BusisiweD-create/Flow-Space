import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/approval_request.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  final List<ApprovalRequest> _approvalRequests = [
    ApprovalRequest(
      id: '1',
      itemName: 'User Authentication System',
      requester: 'John Doe',
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: ApprovalStatus.pending,
      description: 'Implementation of secure user login system with JWT tokens',
    ),
    ApprovalRequest(
      id: '2',
      itemName: 'Database Schema Update',
      requester: 'Jane Smith',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: ApprovalStatus.pending,
      description: 'Update database schema to support new user roles',
    ),
    ApprovalRequest(
      id: '3',
      itemName: 'API Documentation',
      requester: 'Mike Johnson',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      status: ApprovalStatus.approved,
      description: 'Complete API documentation with examples and endpoints',
    ),
  ];

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
                      request.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Requested by: ${request.requester}'),
                        Text('Date: ${_formatDate(request.date)}'),
                        if (request.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              request.description,
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
                                tooltip: 'Deny',
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
      case ApprovalStatus.denied:
        return FlownetColors.crimsonRed;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _approveRequest(String id) {
    setState(() {
      final index = _approvalRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _approvalRequests[index] = _approvalRequests[index].copyWith(
          status: ApprovalStatus.approved,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request approved successfully'),
        backgroundColor: FlownetColors.emeraldGreen,
      ),
    );
  }

  void _denyRequest(String id) {
    setState(() {
      final index = _approvalRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _approvalRequests[index] = _approvalRequests[index].copyWith(
          status: ApprovalStatus.denied,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request denied'),
        backgroundColor: FlownetColors.crimsonRed,
      ),
    );
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
}
