import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deliverable.dart';
import '../models/sign_off_report.dart';
import '../services/backend_api_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class ClientReviewScreen extends ConsumerStatefulWidget {
  final String reportId;
  
  const ClientReviewScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<ClientReviewScreen> createState() => _ClientReviewScreenState();
}

class _ClientReviewScreenState extends ConsumerState<ClientReviewScreen> {
  final _commentController = TextEditingController();
  final _changeRequestController = TextEditingController();
  
  SignOffReport? _report;
  Deliverable? _deliverable;
  bool _isSubmitting = false;
  String _selectedAction = '';

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final backendService = BackendApiService();
      
      // Fetch sign-off report
      final reportResponse = await backendService.getSignOffReport(widget.reportId);
      if (reportResponse.isSuccess && reportResponse.data != null) {
        _report = SignOffReport.fromJson(reportResponse.data!);
        
        // Fetch deliverable data
        if (_report != null && _report!.deliverableId.isNotEmpty) {
          final deliverableResponse = await backendService.getDeliverable(_report!.deliverableId);
          if (deliverableResponse.isSuccess && deliverableResponse.data != null) {
            _deliverable = Deliverable.fromJson(deliverableResponse.data!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading report data: $e');
      // Fallback to empty data rather than mock data
      _report = SignOffReport(
        id: widget.reportId,
        deliverableId: '',
        reportTitle: 'Sign-Off Report',
        reportContent: 'Report data could not be loaded.',
        sprintIds: [],
        status: ReportStatus.draft,
        createdAt: DateTime.now(),
        createdBy: '',
        submittedAt: null,
        submittedBy: '',
      );
      
      _deliverable = Deliverable(
        id: '',
        title: 'Deliverable',
        description: 'Deliverable data could not be loaded.',
        status: DeliverableStatus.draft,
        createdAt: DateTime.now(),
        dueDate: DateTime.now(),
        sprintIds: [],
        definitionOfDone: [],
        evidenceLinks: [],
        submittedBy: '',
        submittedAt: null,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitApproval() async {
    if (_selectedAction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an action (Approve or Request Changes)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAction == 'changeRequest' && _changeRequestController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details for the change request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final backendService = BackendApiService();
      
      if (_selectedAction == 'approve') {
        // Approve the deliverable
        final response = await backendService.approveDeliverable(
          _deliverable!.id,
          _commentController.text.isNotEmpty ? _commentController.text : null,
        );
        
        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deliverable approved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve deliverable: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (_selectedAction == 'changeRequest') {
        // Request changes
        final response = await backendService.requestChanges(
          _deliverable!.id,
          _changeRequestController.text,
        );
        
        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Change request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit change request: ${response.error}'),
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_report == null || _deliverable == null) {
      return const Scaffold(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Client Review & Approval',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review the deliverable and provide your decision',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: FlownetColors.coolGray,
              ),
            ),
            const SizedBox(height: 24),

            // Deliverable Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Report Content
            _buildReportContent(),
            const SizedBox(height: 24),

            // Review Actions
            _buildReviewActions(),
            const SizedBox(height: 24),

            // Digital Signature Section
            _buildDigitalSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment,
                  color: FlownetColors.electricBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deliverable Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FlownetColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem('Title', _deliverable!.title),
                ),
                Expanded(
                  child: _buildStatusItem('Status', _deliverable!.statusDisplayName),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem('Due Date', _formatDate(_deliverable!.dueDate)),
                ),
                Expanded(
                  child: _buildStatusItem('Submitted By', _deliverable!.submittedBy ?? 'Unknown'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description,
                  color: FlownetColors.electricBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sign-Off Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FlownetColors.pureWhite,
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
                  color: Colors.black,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewActions() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Decision',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Approve', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Accept the deliverable as complete', style: TextStyle(color: Colors.grey)),
                    value: 'approve',
                    // ignore: deprecated_member_use
                    groupValue: _selectedAction,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value!;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Request Changes', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Request modifications before approval', style: TextStyle(color: Colors.grey)),
                    value: 'changeRequest',
                    // ignore: deprecated_member_use
                    groupValue: _selectedAction,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value!;
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comments
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comments (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
                hintText: 'Add any additional comments...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Change Request Details
            if (_selectedAction == 'changeRequest') ...[
              TextFormField(
                controller: _changeRequestController,
                decoration: const InputDecoration(
                  labelText: 'Change Request Details *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                  hintText: 'Describe the required changes...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (_selectedAction == 'changeRequest' && (value?.isEmpty ?? true)) {
                    return 'Please provide change request details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalSignatureSection() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Signature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FlownetColors.slate,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FlownetColors.electricBlue),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.draw,
                    color: Colors.grey,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Digital Signature',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'By submitting this review, you digitally sign and approve this deliverable',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApproval,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAction == 'approve' 
                      ? Colors.green 
                      : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedAction == 'approve' 
                            ? 'Approve Deliverable'
                            : 'Submit Change Request',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _changeRequestController.dispose();
    super.dispose();
  }
}
