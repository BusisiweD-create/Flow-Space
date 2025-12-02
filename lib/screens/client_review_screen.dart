import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/deliverable.dart';
import '../models/sign_off_report.dart';
import '../services/backend_api_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/signature_capture_widget.dart';

class ClientReviewScreen extends ConsumerStatefulWidget {
  final String reportId;
  final SignOffReport? initialReport;
  final Deliverable? initialDeliverable;
  
  const ClientReviewScreen({
    super.key,
    required this.reportId,
    this.initialReport,
    this.initialDeliverable,
  });

  @override
  ConsumerState<ClientReviewScreen> createState() => _ClientReviewScreenState();
}

class _ClientReviewScreenState extends ConsumerState<ClientReviewScreen> {
  final _commentController = TextEditingController();
  final _changeRequestController = TextEditingController();
  final GlobalKey<SignatureCaptureWidgetState> _signatureKey = GlobalKey<SignatureCaptureWidgetState>();
  String? _capturedSignature;
  
  SignOffReport? _report;
  Deliverable? _deliverable;
  bool _isSubmitting = false;
  String _selectedAction = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      _report = widget.initialReport;
      _deliverable = widget.initialDeliverable;
      final needsFullFetch = (_report?.reportContent.isEmpty ?? true) || (_report?.deliverableId.isEmpty ?? true);
      if (needsFullFetch) {
        // Fetch full report details in background
        _loadReportData();
      } else if (_deliverable == null && _report != null && _report!.deliverableId.isNotEmpty) {
        // Fetch deliverable in background without blocking initial render
        _loadDeliverable(_report!.deliverableId);
      }
    } else {
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    try {
      final api = BackendApiService();
      final reportResp = await api.getSignOffReport(widget.reportId);
      if (!mounted) return;
      if (reportResp.isSuccess && reportResp.data != null) {
        final reportJson = reportResp.data!['data'] ?? reportResp.data!['report'] ?? reportResp.data!;
        final loadedReport = SignOffReport.fromJson(reportJson);
        Deliverable? loadedDeliverable;
        if (loadedReport.deliverableId.isNotEmpty) {
          final delivResp = await api.getDeliverable(loadedReport.deliverableId);
          if (delivResp.isSuccess && delivResp.data != null) {
            final dJson = delivResp.data!['data'] ?? delivResp.data!['deliverable'] ?? delivResp.data!;
            loadedDeliverable = Deliverable.fromJson(dJson);
          }
        }
        setState(() {
          _report = loadedReport;
          _deliverable = loadedDeliverable;
        });
      } else {
        setState(() {
          _report = null;
          _deliverable = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _deliverable = null;
      });
    }
  }

  Future<void> _loadDeliverable(String deliverableId) async {
    try {
      final api = BackendApiService();
      final delivResp = await api.getDeliverable(deliverableId);
      if (!mounted) return;
      if (delivResp.isSuccess && delivResp.data != null) {
        final dJson = delivResp.data!['data'] ?? delivResp.data!['deliverable'] ?? delivResp.data!;
        setState(() {
          _deliverable = Deliverable.fromJson(dJson);
        });
      }
    } catch (_) {}
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
        String? signature = _capturedSignature;
        signature ??= await _signatureKey.currentState?.getSignature();
        if (signature == null || signature.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Digital signature is required to approve this report.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        final response = await backendService.approveSignOffReport(
          widget.reportId,
          _commentController.text.isNotEmpty ? _commentController.text : null,
          signature,
        );
        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report approved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _report = _report?.copyWith(status: ReportStatus.approved);
          });
          context.go('/enhanced-client-review/${widget.reportId}');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve report: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (_selectedAction == 'changeRequest') {
        final response = await backendService.requestSignOffChanges(
          widget.reportId,
          _changeRequestController.text,
        );
        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Change request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _report = _report?.copyWith(status: ReportStatus.changeRequested);
          });
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

  Widget buildStatusCard() {
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
            if (_deliverable == null && (_report?.deliverableId.isEmpty ?? true)) ...[
              buildStatusItem('Linked Deliverable', 'None'),
            ] else if (_deliverable == null) ...[
              const LinearProgressIndicator(),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: buildStatusItem('Title', _deliverable!.title),
                  ),
                  Expanded(
                    child: buildStatusItem('Status', _deliverable!.statusDisplayName),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: buildStatusItem('Due Date', formatDate(_deliverable!.dueDate)),
                  ),
                  Expanded(
                    child: buildStatusItem('Submitted By', _deliverable!.submittedBy ?? 'Unknown'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildStatusItem(String label, String value) {
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

  Widget buildReportContent() {
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

  Widget buildReviewActions() {
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

  Widget buildDigitalSignatureSection() {
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
            SignatureCaptureWidget(
              key: _signatureKey,
              onSignatureCaptured: (sig) {
                setState(() {
                  _capturedSignature = sig;
                });
              },
            ),
            const SizedBox(height: 16),
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
                            ? 'Approve Report'
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

  String formatDate(DateTime date) {
    final tz = date.toUtc().add(const Duration(hours: 2));
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(tz.day)}/${two(tz.month)}/${tz.year} ${two(tz.hour)}:${two(tz.minute)}';
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
            buildStatusCard(),
            const SizedBox(height: 24),

            // Report Content
            if (_report == null || (_report!.reportContent.isEmpty))
              const Center(child: CircularProgressIndicator())
            else
              buildReportContent(),
            const SizedBox(height: 24),

            // Review Actions
            buildReviewActions(),
            const SizedBox(height: 24),

            // Digital Signature Section
            buildDigitalSignatureSection(),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _commentController.dispose();
    _changeRequestController.dispose();
    super.dispose();
  }
}
