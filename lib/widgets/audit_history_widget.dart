import 'package:flutter/material.dart';
import '../theme/flownet_theme.dart';
import '../services/document_service.dart';
import '../services/sign_off_report_service.dart';

class AuditHistoryWidget extends StatefulWidget {
  final String? documentId;
  final String? reportId;
  final DocumentService? documentService;
  final SignOffReportService? reportService;

  const AuditHistoryWidget({
    super.key,
    this.documentId,
    this.reportId,
    this.documentService,
    this.reportService,
  }) : assert(documentId != null || reportId != null, 'Either documentId or reportId must be provided');

  @override
  State<AuditHistoryWidget> createState() => _AuditHistoryWidgetState();
}

class _AuditHistoryWidgetState extends State<AuditHistoryWidget> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuditHistory();
  }

  Future<void> _loadAuditHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.documentId != null && widget.documentService != null) {
        final response = await widget.documentService!.getDocumentAudit(widget.documentId!);
        if (response.isSuccess && response.data != null) {
          setState(() {
            _auditLogs = (response.data!['audit'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.error ?? 'Failed to load audit history';
            _isLoading = false;
          });
        }
      } else if (widget.reportId != null && widget.reportService != null) {
        final response = await widget.reportService!.getReportAudit(widget.reportId!);
        if (response.isSuccess && response.data != null) {
          setState(() {
            _auditLogs = (response.data!['audit'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.error ?? 'Failed to load audit history';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading audit history: $e';
        _isLoading = false;
      });
    }
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'create_report':
        return 'Report Created';
      case 'update_report':
        return 'Report Updated';
      case 'submit_report':
        return 'Report Submitted';
      case 'approve_report':
        return 'Report Approved';
      case 'request_changes':
        return 'Changes Requested';
      case 'view_report':
        return 'Report Viewed';
      case 'view_document':
        return 'Document Viewed';
      case 'document_upload':
        return 'Document Uploaded';
      case 'document_download':
        return 'Document Downloaded';
      case 'document_delete':
        return 'Document Deleted';
      default:
        return action.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        ).join(' ');
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create_report':
      case 'document_upload':
        return Icons.add_circle;
      case 'update_report':
        return Icons.edit;
      case 'submit_report':
        return Icons.send;
      case 'approve_report':
        return Icons.check_circle;
      case 'request_changes':
        return Icons.change_circle;
      case 'view_report':
      case 'view_document':
        return Icons.visibility;
      case 'document_download':
        return Icons.download;
      case 'document_delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve_report':
        return FlownetColors.emeraldGreen;
      case 'request_changes':
        return FlownetColors.amberOrange;
      case 'document_delete':
        return FlownetColors.crimsonRed;
      case 'submit_report':
      case 'create_report':
      case 'document_upload':
        return FlownetColors.electricBlue;
      default:
        return FlownetColors.coolGray;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.electricBlue),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: FlownetColors.crimsonRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: FlownetColors.crimsonRed,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAuditHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_auditLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: FlownetColors.coolGray,
            ),
            SizedBox(height: 16),
            Text(
              'No audit history available',
              style: TextStyle(
                color: FlownetColors.coolGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final action = log['action'] as String? ?? 'unknown';
        final actorName = log['actor_name'] as String? ?? 'Unknown User';
        final createdAt = log['created_at'] != null 
            ? DateTime.parse(log['created_at']).toLocal()
            : null;
        final details = log['details'] as Map<String, dynamic>? ?? {};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FlownetColors.graphiteGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getActionColor(action).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActionColor(action).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActionIcon(action),
                  color: _getActionColor(action),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActionDisplayName(action),
                      style: const TextStyle(
                        color: FlownetColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By: $actorName',
                      style: const TextStyle(
                        color: FlownetColors.coolGray,
                        fontSize: 12,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: FlownetColors.coolGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details.toString(),
                        style: const TextStyle(
                          color: FlownetColors.coolGray,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

