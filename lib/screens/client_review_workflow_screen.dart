import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sign_off_report.dart';
import '../models/user_role.dart';
import '../services/sign_off_report_service.dart';
import '../services/deliverable_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/signature_capture_widget.dart';
import '../widgets/signature_display_widget.dart';

class ClientReviewWorkflowScreen extends ConsumerStatefulWidget {
  final String reportId;
  
  const ClientReviewWorkflowScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<ClientReviewWorkflowScreen> createState() => _ClientReviewWorkflowScreenState();
}

class _ClientReviewWorkflowScreenState extends ConsumerState<ClientReviewWorkflowScreen> {
  final _commentController = TextEditingController();
  final _changeRequestController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SignatureCaptureWidgetState> _signatureKey = GlobalKey<SignatureCaptureWidgetState>();
  
  final SignOffReportService _reportService = SignOffReportService(AuthService());
  final DeliverableService _deliverableService = DeliverableService();
  
  SignOffReport? _report;
  Map<String, dynamic>? _deliverable;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedAction; // 'approve' or 'request_changes'
  List<Map<String, dynamic>> _signatures = []; // Store digital signatures

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load report
      final reportResponse = await _reportService.getSignOffReport(widget.reportId);
      if (reportResponse.isSuccess && reportResponse.data != null) {
        // ApiClient already extracts the 'data' field, so response.data is the report object directly
        // But check if it's nested in a 'data' key or is the report directly
        final data = reportResponse.data is Map && reportResponse.data!['data'] != null
            ? reportResponse.data!['data'] as Map<String, dynamic>
            : reportResponse.data as Map<String, dynamic>;
        
        final contentRaw = data['content'];
        final content = contentRaw is Map<String, dynamic>
            ? contentRaw
            : contentRaw is Map
                ? Map<String, dynamic>.from(contentRaw)
                : <String, dynamic>{};
        final reviews = data['reviews'] as List? ?? [];
        
        setState(() {
          _report = SignOffReport(
            id: data['id'] as String,
            deliverableId: data['deliverableId'] as String? ?? data['deliverable_id'] as String? ?? '',
            reportTitle: content['reportTitle'] as String? ?? 'Untitled Report',
            reportContent: content['reportContent'] as String? ?? '',
            sprintIds: (content['sprintIds'] as List?)?.cast<String>() ?? [],
            knownLimitations: content['knownLimitations'] as String?,
            nextSteps: content['nextSteps'] as String?,
            status: _parseStatus(data['status'] as String? ?? 'draft'),
            createdAt: DateTime.parse(data['createdAt'] ?? data['created_at']).toLocal(),
            createdBy: data['createdByName'] as String? ?? data['created_by_name'] as String? ?? 'Unknown',
            digitalSignature: content['digitalSignature'] as String?,
          );
          
          _reviews = reviews.cast<Map<String, dynamic>>();
          
          // Load deliverable details
          if (_report!.deliverableId.isNotEmpty) {
            _loadDeliverable(_report!.deliverableId);
          }
        });
        
        // Load digital signatures
        await _loadSignatures();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSignatures() async {
    try {
      final ApiClient apiClient = ApiClient();
      final response = await apiClient.get('/sign-off-reports/${widget.reportId}/signatures');
      
      if (response.isSuccess && response.data != null) {
        final signaturesData = response.data!['data'] as List? ?? [];
        setState(() {
          _signatures = signaturesData.cast<Map<String, dynamic>>();
        });
        debugPrint('✅ Loaded ${_signatures.length} signatures for report');
      }
    } catch (e) {
      debugPrint('Error loading signatures: $e');
      // Don't show error to user - signatures are optional display
    }
  }

  Future<void> _loadDeliverable(String deliverableId) async {
    try {
      final response = await _deliverableService.getDeliverables();
      if (response.isSuccess && response.data != null) {
        final deliverables = response.data!['deliverables'] as List;
        final deliverable = deliverables.firstWhere(
          (d) => d['id'] == deliverableId,
          orElse: () => null,
        );
        if (deliverable != null) {
          setState(() => _deliverable = deliverable as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // Silently fail - deliverable is optional
    }
  }

  ReportStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'approved':
        return ReportStatus.approved;
      case 'change_requested':
      case 'change_request':
        return ReportStatus.changeRequested;
      default:
        return ReportStatus.draft;
    }
  }

  Future<void> _handleApproval() async {
    if (_selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Approve or Request Changes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAction == 'request_changes' && _changeRequestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details for the change request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      ApiResponse response;
      
      if (_selectedAction == 'approve') {
        // Capture signature - MANDATORY for approval
        String? signature;
        if (_signatureKey.currentState != null) {
          signature = await _signatureKey.currentState!.getSignature();
        }
        
        // Validate signature exists
        if (signature == null || signature.isEmpty) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Digital signature is required to approve this report. Please sign in the signature box above.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        response = await _reportService.approveReport(
          widget.reportId,
          comment: _commentController.text.trim().isNotEmpty 
              ? _commentController.text.trim() 
              : null,
          digitalSignature: signature,
        );
      } else {
        response = await _reportService.requestChanges(
          widget.reportId,
          _changeRequestController.text.trim(),
        );
      }

      if (response.isSuccess) {
        // Reload signatures after approval to show the new signature
        if (_selectedAction == 'approve') {
          await _loadSignatures();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedAction == 'approve' 
                  ? '✅ Report approved successfully!' 
                  : 'Change request submitted successfully!',),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildReportDisplay() {
    if (_report == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deliverable Summary
        if (_deliverable != null) ...[
          Card(
            color: FlownetColors.graphiteGray,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment, color: FlownetColors.electricBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Deliverable Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: FlownetColors.pureWhite,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _deliverable!['title'] as String? ?? 'Untitled',
                    style: const TextStyle(
                      color: FlownetColors.pureWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_deliverable!['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _deliverable!['description'] as String,
                      style: const TextStyle(color: FlownetColors.coolGray),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          _deliverable!['status'] as String? ?? 'Unknown',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: FlownetColors.electricBlue.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      if (_deliverable!['priority'] != null)
                        Chip(
                          label: Text(
                            _deliverable!['priority'] as String,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: FlownetColors.graphiteGray,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Report Title
        Text(
          _report!.reportTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        // Report Content
        Card(
          color: FlownetColors.graphiteGray,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, color: FlownetColors.electricBlue),
                    SizedBox(width: 8),
                    Text(
                      'Report Content',
                      style: TextStyle(
                        color: FlownetColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _report!.reportContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Known Limitations
        if (_report!.knownLimitations != null && _report!.knownLimitations!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: FlownetColors.graphiteGray,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Known Limitations',
                        style: TextStyle(
                          color: FlownetColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _report!.knownLimitations!,
                    style: const TextStyle(color: FlownetColors.coolGray),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Next Steps
        if (_report!.nextSteps != null && _report!.nextSteps!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: FlownetColors.graphiteGray,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_forward, color: FlownetColors.electricBlue),
                      SizedBox(width: 8),
                      Text(
                        'Next Steps',
                        style: TextStyle(
                          color: FlownetColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _report!.nextSteps!,
                    style: const TextStyle(color: FlownetColors.coolGray),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Previous Reviews
        if (_reviews.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Previous Reviews',
            style: TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._reviews.map((review) => Card(
                color: FlownetColors.graphiteGray,
                child: ListTile(
                  leading: Icon(
                    review['status'] == 'approved' ? Icons.check_circle : Icons.edit,
                    color: review['status'] == 'approved' 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                  title: Text(
                    review['reviewerName'] as String? ?? 'Unknown Reviewer',
                    style: const TextStyle(color: FlownetColors.pureWhite),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['status'] == 'approved' ? 'Approved' : 'Requested Changes',
                        style: TextStyle(
                          color: review['status'] == 'approved' 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                      if (review['feedback'] != null)
                        Text(
                          review['feedback'] as String,
                          style: const TextStyle(color: FlownetColors.coolGray),
                        ),
                    ],
                  ),
                  trailing: review['approved_at'] != null
                      ? Text(
                          _formatDate(DateTime.parse(review['approved_at'])),
                          style: const TextStyle(color: FlownetColors.coolGray, fontSize: 12),
                        )
                      : null,
                ),
              ),),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getSignatureTitle(String? role) {
    switch (role?.toLowerCase()) {
      case 'deliverylead':
        return 'Delivery Lead Signature';
      case 'clientreviewer':
        return 'Client Approval Signature';
      case 'systemadmin':
        return 'System Admin Signature';
      default:
        return 'Digital Signature';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _changeRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = AuthService().currentUser?.role;
    final canReview = userRole == UserRole.clientReviewer || userRole == UserRole.systemAdmin;
    final isApproved = _report?.status == ReportStatus.approved;

    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportDisplay(),
                  
                  // Review Section (only if can review and not already approved)
                  if (canReview && !isApproved && _report?.status == ReportStatus.submitted) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client Review & Approval',
                            style: TextStyle(
                              color: FlownetColors.pureWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Action Selection
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'approve',
                                label: Text('Approve'),
                                icon: Icon(Icons.check_circle),
                              ),
                              ButtonSegment<String>(
                                value: 'request_changes',
                                label: Text('Request Changes'),
                                icon: Icon(Icons.edit_note),
                              ),
                            ],
                            selected: <String>{if (_selectedAction != null) _selectedAction!},
                            emptySelectionAllowed: true,
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedAction = newSelection.firstOrNull;
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              selectedForegroundColor: FlownetColors.pureWhite,
                              foregroundColor: FlownetColors.coolGray,
                            ),
                          ),
                          
                          // Comment (for approval)
                          if (_selectedAction == 'approve') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                labelText: 'Comment (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.comment),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            // Digital Signature
                            SignatureCaptureWidget(
                              key: _signatureKey,
                              onSignatureCaptured: (signature) {
                                // Signature captured callback
                              },
                              existingSignature: _report?.digitalSignature,
                            ),
                          ],
                          
                          // Change Request Details (required for request changes)
                          if (_selectedAction == 'request_changes') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _changeRequestController,
                              decoration: const InputDecoration(
                                labelText: 'Change Request Details *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.edit_note),
                                helperText: 'Please provide clear details about what changes are needed',
                              ),
                              maxLines: 6,
                              validator: (value) {
                                if (_selectedAction == 'request_changes' && 
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Change request details are required';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _handleApproval,
                              icon: Icon(_selectedAction == 'approve' 
                                  ? Icons.check_circle 
                                  : Icons.edit_note,),
                              label: Text(_isSubmitting 
                                  ? 'Submitting...' 
                                  : _selectedAction == 'approve' 
                                      ? 'Approve Report' 
                                      : 'Request Changes',),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedAction == 'approve'
                                    ? Colors.green
                                    : Colors.orange,
                                foregroundColor: FlownetColors.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Approved Status Banner with Signatures
                  if (isApproved) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This report has been approved and sealed. No further changes are allowed.',
                              style: TextStyle(color: Colors.green, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Display all digital signatures
                    if (_signatures.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Digital Signatures',
                        style: TextStyle(
                          color: FlownetColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Display each signature
                      ..._signatures.map((sig) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SignatureDisplayWidget(
                            signatureData: sig['signature_data'] as String?,
                            signerName: sig['signer_name'] as String? ?? 'Unknown',
                            signerRole: sig['signer_role'] as String? ?? 'unknown',
                            signedDate: DateTime.parse(sig['signed_at'] as String),
                            title: _getSignatureTitle(sig['signer_role'] as String?),
                            isVerified: sig['is_valid'] as bool? ?? true,
                            signatureType: sig['signature_type'] as String? ?? 'manual',
                          ),
                        );
                      }),
                    ],
                  ],
                  
                  // Change Requested Status
                  if (_report?.status == ReportStatus.changeRequested) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note, color: Colors.orange, size: 32),
                              SizedBox(width: 12),
                              Text(
                                'Changes Requested',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This report has been reopened for changes. Please review the feedback and update the report accordingly.',
                            style: TextStyle(color: Colors.orange),
                          ),
                          if (_reviews.isNotEmpty && _reviews.last['feedback'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _reviews.last['feedback'] as String,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

