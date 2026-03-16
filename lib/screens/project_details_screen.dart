import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      useBackgroundImage: true,
      centered: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withAlpha(128)),
                        ),
                        child: Icon(
                          Icons.folder,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              project.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(179),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getProjectStatusColor(project.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatProjectStatus(project.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Project Information
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (project.description.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      Icons.description,
                      'Description',
                      project.description,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    'Start Date',
                    _formatDate(project.startDate),
                  ),
                  const SizedBox(height: 12),
                  if (project.endDate != null) ...[
                    _buildDetailRow(
                      context,
                      Icons.event,
                      'End Date',
                      _formatDate(project.endDate!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildDetailRow(
                    context,
                    Icons.category,
                    'Priority',
                    _formatProjectPriority(project.priority),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.business,
                    'Type',
                    project.projectType,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/sprint-console?projectId=${project.id}');
                      },
                      icon: const Icon(Icons.timer),
                      label: const Text('Manage Sprints'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/project-workspace/${project.id}');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Project'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/projects');
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Projects'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withAlpha(179),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(230),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.completed:
        return Colors.blue;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatProjectStatus(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatProjectPriority(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.low:
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

}
