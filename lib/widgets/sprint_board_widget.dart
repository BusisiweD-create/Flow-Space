import 'package:flutter/material.dart';
import '../services/jira_service.dart';
import '../theme/flownet_theme.dart';

class SprintBoardWidget extends StatefulWidget {
  final String sprintId;
  final String sprintName;
  final List<JiraIssue> issues;
  final Function(JiraIssue issue, String newStatus)? onIssueStatusChanged;

  const SprintBoardWidget({
    super.key,
    required this.sprintId,
    required this.sprintName,
    required this.issues,
    this.onIssueStatusChanged,
  });

  @override
  State<SprintBoardWidget> createState() => _SprintBoardWidgetState();
}

class _SprintBoardWidgetState extends State<SprintBoardWidget> {
  
  // Group issues by status
  Map<String, List<JiraIssue>> get _groupedIssues {
    final Map<String, List<JiraIssue>> grouped = {};
    
    for (final issue in widget.issues) {
      final status = issue.status ?? 'Unknown';
      grouped.putIfAbsent(status, () => []).add(issue);
    }
    
    return grouped;
  }

  // Define column order and colors
  List<Map<String, dynamic>> get _columns {
    return [
      {
        'status': 'To Do',
        'color': Colors.grey,
        'icon': Icons.assignment_outlined,
      },
      {
        'status': 'In Progress',
        'color': Colors.orange,
        'icon': Icons.play_arrow,
      },
      {
        'status': 'In Review',
        'color': Colors.blue,
        'icon': Icons.visibility,
      },
      {
        'status': 'Done',
        'color': Colors.green,
        'icon': Icons.check_circle,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sprint Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlownetColors.electricBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: FlownetColors.electricBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sprintName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: FlownetColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.issues.length} issues',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSprintStats(),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Kanban Board - responsive columns, no horizontal scroll
        LayoutBuilder(
          builder: (context, constraints) {
            // 4 columns with 16px spacing between them
            const double spacing = 16;
            final double totalSpacing = spacing * (_columns.length - 1);
            final double columnWidth =
                (constraints.maxWidth - totalSpacing).clamp(220.0, double.infinity) /
                    _columns.length;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _columns.length; i++)
                  Padding(
                    padding: EdgeInsets.only(right: i == _columns.length - 1 ? 0 : spacing),
                    child: SizedBox(
                      width: columnWidth,
                      child: _buildColumn(_columns[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSprintStats() {
    final totalIssues = widget.issues.length;
    final completedIssues = widget.issues.where((issue) => issue.status == 'Done').length;
    final progress = totalIssues > 0 ? (completedIssues / totalIssues) * 100 : 0.0;

    return Row(
      children: [
        _buildStatItem('Progress', '${progress.toStringAsFixed(1)}%'),
        const SizedBox(width: 16),
        _buildStatItem('Completed', '$completedIssues/$totalIssues'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: FlownetColors.electricBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: FlownetColors.pureWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(Map<String, dynamic> column) {
    final status = column['status'] as String;
    final color = column['color'] as Color;
    final icon = column['icon'] as IconData;
    final issues = _groupedIssues[status] ?? [];

    return Container(
      margin: const EdgeInsets.only(right: 0),
      child: DragTarget<JiraIssue>(
        onAcceptWithDetails: (details) {
          final issue = details.data;
          if (widget.onIssueStatusChanged != null) {
            widget.onIssueStatusChanged!(issue, status);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: candidateData.isNotEmpty
                  ? Border.all(color: color, width: 2)
                  : null,
            ),
            child: SizedBox(
              height: 600, // Fixed height to prevent unbounded constraints
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Column Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${issues.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Issues List
          Expanded(
            child: issues.isEmpty
                ? _buildEmptyColumn(status)
                : ListView.builder(
                    itemCount: issues.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildIssueCard(issues[index]),
                      );
                    },
                  ),
          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyColumn(String status) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FlownetColors.pureWhite.withValues(alpha: 0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: FlownetColors.pureWhite.withValues(alpha: 0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No $status issues',
              style: TextStyle(
                color: FlownetColors.pureWhite.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(JiraIssue issue) {
    return Draggable<JiraIssue>(
      data: issue,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FlownetColors.charcoalBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: FlownetColors.electricBlue,
              width: 2,
            ),
          ),
          child: Text(
            issue.summary,
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlownetColors.pureWhite.withValues(alpha: 0.1),
          ),
        ),
        child: const Center(
          child: Text(
            'Moving...',
            style: TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 12,
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlownetColors.pureWhite.withValues(alpha: 0.1),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Key and Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FlownetColors.electricBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  issue.key,
                  style: const TextStyle(
                    color: FlownetColors.electricBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (issue.issueType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.issueType!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Issue Summary
          Text(
            issue.summary,
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Issue Details
          Row(
            children: [
              if (issue.priority != null) ...[
                _buildPriorityChip(issue.priority!),
                const SizedBox(width: 8),
              ],
              if (issue.assignee != null) ...[
                Icon(
                  Icons.person,
                  size: 14,
                  color: FlownetColors.pureWhite.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    issue.assignee!,
                    style: TextStyle(
                      color: FlownetColors.pureWhite.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Labels
          if (issue.labels != null && issue.labels!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: issue.labels!.take(3).map((label) => _buildLabelChip(label)).toList(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: priorityColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FlownetColors.electricBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FlownetColors.electricBlue,
          fontSize: 10,
        ),
      ),
    );
  }
}
