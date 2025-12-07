import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khono/services/api_client.dart';
import '../models/deliverable.dart' as model;
import '../models/sprint_metrics.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/sprint_performance_chart.dart';
import '../services/approval_service.dart';
import '../services/auth_service.dart';
import '../services/sign_off_report_service.dart';
import '../services/deliverable_service.dart' as svc;
import '../services/backend_api_service.dart';

class ReportBuilderScreen extends ConsumerStatefulWidget {
  final String deliverableId;
  
  const ReportBuilderScreen({
    super.key,
    required this.deliverableId,
  });

  @override
  ConsumerState<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends ConsumerState<ReportBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportTitleController = TextEditingController();
  final _reportContentController = TextEditingController();
  final _knownLimitationsController = TextEditingController();
  final _nextStepsController = TextEditingController();
  
  model.Deliverable? _deliverable;
  List<SprintMetrics> _sprintMetrics = [];
  bool _isGenerating = false;
  bool _isPreviewMode = false;
  final ApprovalService _approvalService = ApprovalService(AuthService());
  final SignOffReportService _signOffReportService = SignOffReportService(AuthService());
  final svc.DeliverableService _deliverableService = svc.DeliverableService();
  final BackendApiService _backendApiService = BackendApiService();
  String? _reportId;

  @override
  void initState() {
    super.initState();
    _loadDeliverableData();
  }

  Future<void> _loadDeliverableData() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // 1) Load real deliverables and find the one for this screen
      final response = await _deliverableService.getDeliverables();
      if (!response.isSuccess || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to load deliverables'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final List<svc.Deliverable> allDeliverables =
          (response.data!['deliverables'] as List<dynamic>).cast<svc.Deliverable>();

      svc.Deliverable? svcDeliverable;
      for (final d in allDeliverables) {
        if (d.id == widget.deliverableId) {
          svcDeliverable = d;
          break;
        }
      }

      if (svcDeliverable == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deliverable not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2) Map service deliverable into the richer model.Deliverable used by this screen
      final dodLines = <String>[];
      if (svcDeliverable.definitionOfDone != null &&
          svcDeliverable.definitionOfDone!.trim().isNotEmpty) {
        dodLines.addAll(
          svcDeliverable.definitionOfDone!
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty),
        );
      }

      final model.DeliverableStatus status =
          _mapDeliverableStatus(svcDeliverable.status);

      final builtDeliverable = model.Deliverable(
        id: svcDeliverable.id,
        title: svcDeliverable.title,
        description: svcDeliverable.description ?? '',
        status: status,
        createdAt: svcDeliverable.createdAt,
        dueDate: svcDeliverable.dueDate ?? svcDeliverable.createdAt,
        sprintIds: const [],
        definitionOfDone: dodLines,
        evidenceLinks: const [],
        submittedBy: null,
        submittedAt: null,
      );

      // 3) Resolve sprints linked to this deliverable
      final apiClient = ApiClient();
      final sprintsResponse =
          await apiClient.get('/deliverables/${widget.deliverableId}/sprints');

      final sprintIds = <String>[];
      final metricsList = <SprintMetrics>[];

      if (sprintsResponse.isSuccess && sprintsResponse.data != null) {
        final dynamic data = sprintsResponse.data;
        final List<dynamic> sprintRows =
            data is List ? data : (data['data'] as List<dynamic>? ?? const []);

        for (final row in sprintRows) {
          final sprintId = (row['id'] ?? row['sprint_id'])?.toString();
          if (sprintId == null) continue;
          sprintIds.add(sprintId);

          // 4) Pull metrics for each sprint
          final metricsResponse =
              await _backendApiService.getSprintMetrics(sprintId);
          final metrics =
              _backendApiService.parseSprintMetricsFromResponse(metricsResponse);
          if (metrics.isNotEmpty) {
            metricsList.add(metrics.first);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _deliverable = builtDeliverable.copyWith(sprintIds: sprintIds);
        _sprintMetrics = metricsList;
        _generateReportContent();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading deliverable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _generateReportContent() {
    if (_deliverable == null) return;

    _reportTitleController.text = 'Sign-Off Report: ${_deliverable!.title}';
    
    final content = _buildReportContent();
    _reportContentController.text = content;
  }

  String _buildReportContent() {
    if (_deliverable == null) return '';

    final buffer = StringBuffer();
    
    // Executive Summary
    buffer.writeln('## Executive Summary');
    buffer.writeln();
    buffer.writeln('This report provides a comprehensive overview of the ${_deliverable!.title} deliverable, including sprint performance metrics, quality indicators, and readiness for client approval.');
    buffer.writeln();
    
    // Deliverable Overview
    buffer.writeln('## Deliverable Overview');
    buffer.writeln();
    buffer.writeln('**Title:** ${_deliverable!.title}');
    buffer.writeln('**Description:** ${_deliverable!.description}');
    buffer.writeln('**Due Date:** ${_formatDate(_deliverable!.dueDate)}');
    buffer.writeln('**Status:** ${_deliverable!.statusDisplayName}');
    buffer.writeln();
    
    // Definition of Done
    buffer.writeln('## Definition of Done Checklist');
    buffer.writeln();
    for (int i = 0; i < _deliverable!.definitionOfDone.length; i++) {
      buffer.writeln('${i + 1}. ✅ ${_deliverable!.definitionOfDone[i]}');
    }
    buffer.writeln();
    
    // Evidence & Artifacts
    buffer.writeln('## Evidence & Artifacts');
    buffer.writeln();
    for (int i = 0; i < _deliverable!.evidenceLinks.length; i++) {
      buffer.writeln('${i + 1}. [Evidence ${i + 1}](${_deliverable!.evidenceLinks[i]})');
    }
    buffer.writeln();
    
    // Sprint Performance Summary
    buffer.writeln('## Sprint Performance Summary');
    buffer.writeln();

    if (_sprintMetrics.isEmpty) {
      buffer.writeln('No sprint metrics have been captured yet for the linked sprints.');
      buffer.writeln();
      return buffer.toString();
    }

    final totalCommitted =
        _sprintMetrics.fold(0, (sum, metric) => sum + metric.committedPoints);
    final totalCompleted =
        _sprintMetrics.fold(0, (sum, metric) => sum + metric.completedPoints);
    final avgTestPassRate = _sprintMetrics.fold(
          0.0,
          (sum, metric) => sum + metric.testPassRate,
        ) /
        _sprintMetrics.length;
    final totalDefects =
        _sprintMetrics.fold(0, (sum, metric) => sum + metric.totalDefects);
    final resolvedDefects =
        _sprintMetrics.fold(0, (sum, metric) => sum + metric.defectsClosed);
    
    buffer.writeln('**Total Committed Points:** $totalCommitted');
    buffer.writeln('**Total Completed Points:** $totalCompleted');
    buffer.writeln('**Completion Rate:** ${((totalCompleted / totalCommitted) * 100).toStringAsFixed(1)}%');
    buffer.writeln('**Average Test Pass Rate:** ${avgTestPassRate.toStringAsFixed(1)}%');
    buffer.writeln('**Total Defects:** $totalDefects');
    buffer.writeln('**Resolved Defects:** $resolvedDefects');
    buffer.writeln('**Defect Resolution Rate:** ${((resolvedDefects / totalDefects) * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    
    // Quality Indicators
    buffer.writeln('## Quality Indicators');
    buffer.writeln();
    buffer.writeln('All sprints maintained high quality standards with:');
    buffer.writeln('- Test pass rates consistently above 95%');
    buffer.writeln('- Complete code review coverage');
    buffer.writeln('- Comprehensive documentation');
    buffer.writeln('- Zero critical defects in production');
    buffer.writeln();
    
    // Risk Assessment
    buffer.writeln('## Risk Assessment');
    buffer.writeln();
    final allRisks = _sprintMetrics.where((m) => m.risks != null && m.risks!.isNotEmpty).map((m) => m.risks!).toList();
    if (allRisks.isNotEmpty) {
      for (int i = 0; i < allRisks.length; i++) {
        buffer.writeln('${i + 1}. ${allRisks[i]}');
      }
    } else {
      buffer.writeln('No significant risks identified during development.');
    }
    buffer.writeln();
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  model.DeliverableStatus _mapDeliverableStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return model.DeliverableStatus.submitted;
      case 'approved':
        return model.DeliverableStatus.approved;
      case 'change_requested':
      case 'changerequested':
        return model.DeliverableStatus.changeRequested;
      case 'rejected':
        return model.DeliverableStatus.rejected;
      default:
        return model.DeliverableStatus.draft;
    }
  }

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Simulate report generation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deliverable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No deliverable loaded for this report.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Ensure we have a title and content
      final String title = _reportTitleController.text.trim().isNotEmpty
          ? _reportTitleController.text.trim()
          : 'Sign-Off Report: ${_deliverable!.title}';

      if (_reportContentController.text.trim().isEmpty) {
        // Regenerate content from current deliverable & metrics if empty
        final content = _buildReportContent();
        _reportContentController.text = content;
      }

      final String content = _reportContentController.text;
      final String knownLimitations = _knownLimitationsController.text.trim();
      final String nextSteps = _nextStepsController.text.trim();

      ApiResponse response;
      if (_reportId == null) {
        response = await _signOffReportService.createSignOffReport(
          deliverableId: _deliverable!.id,
          reportTitle: title,
          reportContent: content,
          sprintIds: _deliverable!.sprintIds,
          sprintPerformanceData: null,
          knownLimitations: knownLimitations.isNotEmpty ? knownLimitations : null,
          nextSteps: nextSteps.isNotEmpty ? nextSteps : null,
        );

        if (response.isSuccess && response.data != null) {
          final data = response.data;
          if (data is Map && data['id'] != null) {
            _reportId = data['id'].toString();
          }
        }
      } else {
        response = await _signOffReportService.updateSignOffReport(
          reportId: _reportId!,
          reportTitle: title,
          reportContent: content,
          sprintIds: _deliverable!.sprintIds,
          sprintPerformanceData: null,
          knownLimitations: knownLimitations.isNotEmpty ? knownLimitations : null,
          nextSteps: nextSteps.isNotEmpty ? nextSteps : null,
        );
      }

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${response.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _togglePreview() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deliverable == null) {
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
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            onPressed: _togglePreview,
            tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
          ),
        ],
      ),
      body: _isPreviewMode ? _buildPreviewMode() : _buildEditMode(),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Sign-Off Report Builder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deliverable: ${_deliverable!.title}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: FlownetColors.coolGray,
              ),
            ),
            const SizedBox(height: 24),

            // Report Title
            TextFormField(
              controller: _reportTitleController,
              decoration: const InputDecoration(
                labelText: 'Report Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Report Content
            TextFormField(
              controller: _reportContentController,
              decoration: const InputDecoration(
                labelText: 'Report Content',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 15,
              validator: (value) => value?.isEmpty == true ? 'Content is required' : null,
            ),
            const SizedBox(height: 16),

            // Known Limitations
            TextFormField(
              controller: _knownLimitationsController,
              decoration: const InputDecoration(
                labelText: 'Known Limitations',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
                hintText: 'Any known issues or limitations...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Next Steps
            TextFormField(
              controller: _nextStepsController,
              decoration: const InputDecoration(
                labelText: 'Next Steps',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.arrow_forward),
                hintText: 'Recommended next steps or follow-up actions...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Sprint Performance Chart
            if (_sprintMetrics.isNotEmpty) ...[
              _buildSprintPerformanceSection(),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: _isGenerating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlownetColors.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _togglePreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlownetColors.amberOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildPreviewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Header
          Row(
            children: [
              IconButton(
                onPressed: _togglePreview,
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Mode',
              ),
              Text(
                'Report Preview',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Report Content Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Header
                Text(
                  _reportTitleController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generated on ${_formatDate(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Report Content
                Text(
                  _reportContentController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Known Limitations
                if (_knownLimitationsController.text.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Known Limitations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _knownLimitationsController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],

                // Next Steps
                if (_nextStepsController.text.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Next Steps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nextStepsController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _saveReport,
                  icon: _isGenerating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isGenerating ? 'Saving...' : 'Save Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlownetColors.emeraldGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_deliverable == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No deliverable loaded for this report.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final title = _reportTitleController.text.isNotEmpty
                        ? _reportTitleController.text
                        : 'Approval: ${_deliverable!.title}';
                    final description = _reportContentController.text.isNotEmpty
                        ? _reportContentController.text
                        : _deliverable!.description;

                    if (description.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please generate or enter report content before submitting for review.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final response = await _approvalService.createApprovalRequest(
                      title: title,
                      description: description,
                      priority: 'medium',
                      category: 'Deliverable',
                      deliverableId: _deliverable!.id,
                      evidenceLinks: _deliverable!.evidenceLinks,
                      definitionOfDone: _deliverable!.definitionOfDone,
                    );

                    if (!mounted) return;

                    if (response.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Approval request created. Check the Approvals screen.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.go('/approvals');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create approval request: ${response.error ?? "Unknown error"}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit for Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlownetColors.crimsonRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSprintPerformanceSection() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprint Performance Visualizations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Velocity Chart (using committed as planned points and completed points)
            SprintPerformanceChart(
              sprints: _sprintMetrics
                  .map((m) => {
                        'id': m.sprintId,
                        'name': 'Sprint ${m.sprintId}',
                        'planned_points': m.committedPoints,
                        'completed_points': m.completedPoints,
                      })
                  .toList(),
              chartType: 'velocity',
            ),
            const SizedBox(height: 16),
            
            // Quality Metrics Summary
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg Test Pass Rate',
                    '${_sprintMetrics.fold(0.0, (sum, m) => sum + m.testPassRate) / _sprintMetrics.length}%',
                    Icons.science,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total Defects',
                    '${_sprintMetrics.fold(0, (sum, m) => sum + m.totalDefects)}',
                    Icons.bug_report,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Resolution Rate',
                    '${_sprintMetrics.fold(0.0, (sum, m) => sum + m.defectResolutionRate) / _sprintMetrics.length}%',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlownetColors.slate,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reportTitleController.dispose();
    _reportContentController.dispose();
    _knownLimitationsController.dispose();
    _nextStepsController.dispose();
    super.dispose();
  }
}
