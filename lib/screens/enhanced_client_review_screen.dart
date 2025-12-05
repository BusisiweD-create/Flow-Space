import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deliverable.dart';
import '../models/sign_off_report.dart';
import '../models/sprint_metrics.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class EnhancedClientReviewScreen extends ConsumerStatefulWidget {
  final String reportId;
  
  const EnhancedClientReviewScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<EnhancedClientReviewScreen> createState() => _EnhancedClientReviewScreenState();
}

class _EnhancedClientReviewScreenState extends ConsumerState<EnhancedClientReviewScreen> {
  final _commentController = TextEditingController();
  final _changeRequestController = TextEditingController();
  
  SignOffReport? _report;
  Deliverable? _deliverable;
  List<SprintMetrics> _sprintMetrics = [];
  bool _isSubmitting = false;
  String _selectedAction = '';
  bool _showAdvancedOptions = false;
  DateTime? _reminderDate;
  String _priority = 'normal';

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() {
    // Mock data - in real app this would come from API
    setState(() {
      _report = SignOffReport(
        id: widget.reportId,
        deliverableId: 'deliverable-1',
        reportTitle: 'Sign-Off Report: User Authentication System',
        reportContent: '''
## Executive Summary

This report provides a comprehensive overview of the User Authentication System deliverable, including sprint performance metrics, quality indicators, and readiness for client approval.

## Deliverable Overview

**Title:** User Authentication System
**Description:** Complete user login, registration, and role-based access control with multi-factor authentication
**Due Date:** 15/12/2024
**Status:** Submitted

## Definition of Done Checklist

1. ✅ All unit tests pass with >90% coverage
2. ✅ Code review completed by senior developer
3. ✅ Security audit passed with no critical issues
4. ✅ Documentation updated and reviewed
5. ✅ Performance benchmarks met
6. ✅ User acceptance testing completed

## Evidence & Artifacts

1. [Demo Environment](https://demo.example.com/auth)
2. [Source Code Repository](https://github.com/company/auth-system)
3. [User Documentation](https://docs.example.com/auth-guide)
4. [Test Coverage Report](https://test-results.example.com/auth-coverage)

## Sprint Performance Summary

**Total Committed Points:** 60
**Total Completed Points:** 56
**Completion Rate:** 93.3%
**Average Test Pass Rate:** 96.9%
**Total Defects:** 6
**Resolved Defects:** 6
**Defect Resolution Rate:** 100.0%

## Quality Indicators

All sprints maintained high quality standards with:
- Test pass rates consistently above 95%
- Complete code review coverage
- Comprehensive documentation
- Zero critical defects in production

## Risk Assessment

No significant risks identified during development.

## Known Limitations

- MFA setup requires admin configuration
- Password reset emails may take up to 5 minutes to deliver
- Session timeout is set to 8 hours for security

## Next Steps

- Deploy to production environment
- Monitor authentication metrics
- Schedule user training sessions
- Plan future enhancements based on user feedback
        ''',
        sprintIds: ['sprint-1', 'sprint-2', 'sprint-3'],
        status: ReportStatus.submitted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'John Doe',
        submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
        submittedBy: 'Project Manager',
      );

      _deliverable = Deliverable(
        id: 'deliverable-1',
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

      // Mock sprint metrics
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
          pointsAddedDuringSprint: 5,
          pointsRemovedDuringSprint: 0,
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
          pointsAddedDuringSprint: 2,
          pointsRemovedDuringSprint: 4,
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
          pointsAddedDuringSprint: 0,
          pointsRemovedDuringSprint: 0,
          uatNotes: 'Final testing completed, all acceptance criteria met',
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
          recordedBy: 'Sprint Lead',
        ),
      ];
    });
  }

  Future<void> _submitApproval() async {
    if (_selectedAction.isEmpty) {
      _showErrorDialog('Please select an action (Approve or Request Changes)');
      return;
    }

    if (_selectedAction == 'changeRequest' && _changeRequestController.text.isEmpty) {
      _showErrorDialog('Please provide details for the change request');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        final message = _selectedAction == 'approve' 
            ? 'Deliverable approved successfully!'
            : 'Change request submitted successfully!';
            
        _showSuccessDialog(message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error submitting review: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _reminderDate = date;
      });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStatsSection(),
            const SizedBox(height: 24),

            // Report Content with Tabs
            _buildReportContentSection(),
            const SizedBox(height: 24),

            // Sprint Performance Visualization
            _buildSprintPerformanceSection(),
            const SizedBox(height: 24),

            // Review Actions
            _buildReviewActionsSection(),
            const SizedBox(height: 24),

            // Advanced Options
            _buildAdvancedOptionsSection(),
            const SizedBox(height: 24),

            // Digital Signature Section
            _buildDigitalSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
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
                Expanded(
                  child: Text(
                    _deliverable!.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: FlownetColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _deliverable!.statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _deliverable!.statusColor),
                  ),
                  child: Text(
                    _deliverable!.statusDisplayName,
                    style: TextStyle(
                      color: _deliverable!.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _deliverable!.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildHeaderItem('Due Date', _formatDate(_deliverable!.dueDate)),
                const SizedBox(width: 24),
                _buildHeaderItem('Submitted By', _deliverable!.submittedBy ?? 'Unknown'),
                const SizedBox(width: 24),
                _buildHeaderItem('Days Remaining', '${_deliverable!.daysUntilDue}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value) {
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

  Widget _buildQuickStatsSection() {
    final totalCommitted = _sprintMetrics.fold(0, (sum, m) => sum + m.committedPoints);
    final totalCompleted = _sprintMetrics.fold(0, (sum, m) => sum + m.completedPoints);
    final avgTestPassRate = _sprintMetrics.fold(0.0, (sum, m) => sum + m.testPassRate) / _sprintMetrics.length;
    final totalDefects = _sprintMetrics.fold(0, (sum, m) => sum + m.totalDefects);
    final resolvedDefects = _sprintMetrics.fold(0, (sum, m) => sum + m.defectsClosed);

    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completion Rate',
                    '${((totalCompleted / totalCommitted) * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Test Pass Rate',
                    '${avgTestPassRate.toStringAsFixed(1)}%',
                    Icons.science,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Defect Resolution',
                    '${((resolvedDefects / totalDefects) * 100).toStringAsFixed(1)}%',
                    Icons.bug_report,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildReportContentSection() {
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

  Widget _buildSprintPerformanceSection() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprint Performance Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._sprintMetrics.map((metric) => _buildSprintMetricCard(metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintMetricCard(SprintMetrics metric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlownetColors.slate,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sprint ${metric.sprintId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: metric.qualityStatusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: metric.qualityStatusColor),
                ),
                child: Text(
                  metric.qualityStatusText,
                  style: TextStyle(
                    color: metric.qualityStatusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Velocity', '${metric.velocity}'),
              ),
              Expanded(
                child: _buildMetricItem('Test Pass', '${metric.testPassRate}%'),
              ),
              Expanded(
                child: _buildMetricItem('Defects', '${metric.netDefects}'),
              ),
            ],
          ),
          if (metric.hasScopeChange) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: metric.scopeChangeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: metric.scopeChangeColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    metric.netScopeChange > 0 ? Icons.trending_up : Icons.trending_down,
                    color: metric.scopeChangeColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scope: ${metric.scopeChangeIndicator}',
                    style: TextStyle(
                      color: metric.scopeChangeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (metric.pointsAddedDuringSprint > 0 || metric.pointsRemovedDuringSprint > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(+${metric.pointsAddedDuringSprint} / -${metric.pointsRemovedDuringSprint})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
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

  Widget _buildReviewActionsSection() {
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

  Widget _buildAdvancedOptionsSection() {
    return Card(
      color: FlownetColors.graphiteGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Advanced Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FlownetColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                ),
              ],
            ),
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 16),
              
              // Priority Selection
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Reminder Date
              InkWell(
                onTap: _selectReminderDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Set Reminder',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  child: Text(
                    _reminderDate != null
                        ? _formatDate(_reminderDate!)
                        : 'No reminder set',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Escalation Options
              CheckboxListTile(
                title: const Text('Escalate if no response in 48 hours'),
                subtitle: const Text('Automatically escalate to project manager'),
                value: false,
                onChanged: (value) {
                  // Handle escalation setting
                },
                activeColor: FlownetColors.electricBlue,
              ),
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
              child: Column(
                children: [
                  const Icon(
                    Icons.draw,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Digital Signature',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'By submitting this review, you digitally sign and approve this deliverable',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Timestamp: ${DateTime.now().toIso8601String()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Review Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to Review:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Review the deliverable details and performance metrics'),
              Text('2. Check the sprint performance and quality indicators'),
              Text('3. Select "Approve" to accept or "Request Changes" to reject'),
              Text('4. Add comments if needed'),
              Text('5. Set priority and reminders if required'),
              Text('6. Submit your decision with digital signature'),
              SizedBox(height: 16),
              Text('Note: Your decision will be recorded with timestamp and cannot be undone.', 
                   style: TextStyle(fontStyle: FontStyle.italic),),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
