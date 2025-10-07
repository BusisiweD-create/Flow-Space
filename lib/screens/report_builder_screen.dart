import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deliverable.dart';
import '../models/sprint_metrics.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/sprint_performance_chart.dart';

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
  
  Deliverable? _deliverable;
  List<SprintMetrics> _sprintMetrics = [];
  bool _isGenerating = false;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _loadDeliverableData();
  }

  void _loadDeliverableData() {
    // Mock data - in real app this would come from API
    setState(() {
      _deliverable = Deliverable(
        id: widget.deliverableId,
        title: 'User Authentication System',
        description: 'Complete user login, registration, and role-based access control with multi-factor authentication',
        status: DeliverableStatus.submitted,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        sprintIds: ['sprint-1', 'sprint-2', 'sprint-3'],
        definitionOfDone: [
          'All unit tests pass with >90% coverage',
          'Code review completed by senior developer',
          'Security audit passed with no critical issues',
          'Documentation updated and reviewed',
          'Performance benchmarks met',
          'User acceptance testing completed',
        ],
        evidenceLinks: [
          'https://demo.example.com/auth',
          'https://github.com/company/auth-system',
          'https://docs.example.com/auth-guide',
          'https://test-results.example.com/auth-coverage',
        ],
        submittedBy: 'John Doe',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      _sprintMetrics = [
        SprintMetrics(
          id: '1',
          sprintId: 'sprint-1',
          committedPoints: 20,
          completedPoints: 18,
          carriedOverPoints: 2,
          testPassRate: 95.5,
          defectsOpened: 3,
          defectsClosed: 3,
          criticalDefects: 0,
          highDefects: 1,
          mediumDefects: 1,
          lowDefects: 1,
          codeReviewCompletion: 100.0,
          documentationStatus: 85.0,
          risks: 'Initial authentication complexity',
          mitigations: 'Extended testing phase, additional security review',
          scopeChanges: 'Added MFA requirement mid-sprint',
          uatNotes: 'Client feedback incorporated successfully',
          recordedAt: DateTime.now().subtract(const Duration(days: 7)),
          recordedBy: 'Sprint Lead',
        ),
        SprintMetrics(
          id: '2',
          sprintId: 'sprint-2',
          committedPoints: 22,
          completedPoints: 20,
          carriedOverPoints: 2,
          testPassRate: 97.2,
          defectsOpened: 2,
          defectsClosed: 2,
          criticalDefects: 0,
          highDefects: 0,
          mediumDefects: 1,
          lowDefects: 1,
          codeReviewCompletion: 100.0,
          documentationStatus: 95.0,
          risks: 'Integration complexity with existing systems',
          mitigations: 'Dedicated integration testing, API documentation',
          scopeChanges: 'Minor UI adjustments based on feedback',
          uatNotes: 'Excellent user feedback, ready for production',
          recordedAt: DateTime.now().subtract(const Duration(days: 4)),
          recordedBy: 'Sprint Lead',
        ),
        SprintMetrics(
          id: '3',
          sprintId: 'sprint-3',
          committedPoints: 18,
          completedPoints: 18,
          carriedOverPoints: 0,
          testPassRate: 98.1,
          defectsOpened: 1,
          defectsClosed: 1,
          criticalDefects: 0,
          highDefects: 0,
          mediumDefects: 0,
          lowDefects: 1,
          codeReviewCompletion: 100.0,
          documentationStatus: 100.0,
          risks: 'None identified',
          mitigations: 'N/A',
          scopeChanges: 'None',
          uatNotes: 'Final testing completed, all acceptance criteria met',
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
          recordedBy: 'Sprint Lead',
        ),
      ];

      // Auto-generate report content
      _generateReportContent();
    });
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
    final totalCommitted = _sprintMetrics.fold(0, (sum, metric) => sum + metric.committedPoints);
    final totalCompleted = _sprintMetrics.fold(0, (sum, metric) => sum + metric.completedPoints);
    final avgTestPassRate = _sprintMetrics.fold(0.0, (sum, metric) => sum + metric.testPassRate) / _sprintMetrics.length;
    final totalDefects = _sprintMetrics.fold(0, (sum, metric) => sum + metric.totalDefects);
    final resolvedDefects = _sprintMetrics.fold(0, (sum, metric) => sum + metric.defectsClosed);
    
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
            _buildSprintPerformanceSection(),
            const SizedBox(height: 24),

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
                  onPressed: _isGenerating ? null : _generateReport,
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
                  onPressed: () {
                    // Navigate to client review
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report ready for client review!'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
            
            // Velocity Chart
            SprintPerformanceChart(
              sprints: _sprintMetrics.map((m) => {
                'id': m.sprintId,
                'name': 'Sprint ${m.sprintId}',
                'velocity': m.velocity,
                'committed': m.committedPoints,
                'completed': m.completedPoints,
              },).toList(),
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
