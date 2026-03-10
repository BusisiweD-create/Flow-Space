import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';
import '../services/project_sprint_service.dart';
import 'package:khono/models/project.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import 'project_workspace_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _selectedProjectId;
  Map<String, dynamic>? _projectSprints;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await ProjectService.getAllProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });

      if (projects.isEmpty) {
        _showEmptyStateMessage();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorMessage(e);
      }
    }
  }

  Future<void> _loadProjectSprints(String projectId) async {
    try {
      final projectSprints =
          await ProjectSprintService.getProjectSprints(projectId);
      if (mounted) {
        setState(() {
          _projectSprints = projectSprints;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sprints: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectProject(Project project) {
    setState(() {
      _selectedProjectId = project.id;
    });
    _loadProjectSprints(project.id);
  }

  void _deselectProject() {
    setState(() {
      _selectedProjectId = null;
      _projectSprints = null;
    });
  }

  void _navigateToSprintConsole(String? projectId, {String? sprintId}) {
    final queryParams = <String, String>{};
    if (projectId != null) queryParams['projectId'] = projectId;
    if (sprintId != null) queryParams['sprintId'] = sprintId;

    final uri = Uri(
        path: '/sprint-console',
        queryParameters: queryParams.isEmpty ? null : queryParams);
    context.go(uri.toString());
  }

  void _navigateToProjectSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProjectWorkspaceScreen(),
      ),
    );
  }

  void _showErrorMessage(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load projects: ${error.toString()}'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadProjects,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showEmptyStateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'No projects found. Create your first project to get started!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return AppScaffold(
      useBackgroundImage: true,
      centered: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                color: primaryColor.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: primaryColor.withAlpha(128)),
                              ),
                              child: Icon(
                                Icons.folder,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Projects',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'View and manage your projects and their sprints',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onSurfaceColor.withAlpha(230),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectedProjectId != null
                                  ? _deselectProject
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: Text(_selectedProjectId != null
                                  ? 'Back to Projects'
                                  : 'All Projects'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedProjectId != null
                                    ? Colors.grey
                                    : primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _navigateToSprintConsole(_selectedProjectId),
                              icon: const Icon(Icons.directions_run),
                              label: Text(_selectedProjectId != null
                                  ? 'View Sprints'
                                  : 'Sprint Console'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _navigateToProjectSetup,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Project'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Projects List or Project Details
                  if (_selectedProjectId == null) ...[
                    _buildProjectsList(),
                  ] else ...[
                    _buildProjectDetails(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProjectsList() {
    if (_projects.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first project to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(179),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToProjectSetup,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Projects',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            final project = _projects[index];
            return _buildProjectCard(project);
          },
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: () => _selectProject(project),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(179),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            project.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(230),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: theme.colorScheme.onSurface.withAlpha(179)),
                    color: Colors.transparent,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility,
                                size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Text('Edit Project'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        debugPrint(
                            'ProjectsScreen: Navigating to project workspace for ID: ${project.id}');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProjectWorkspaceScreen(projectId: project.id),
                          ),
                        );
                      } else if (value == 'edit') {
                        debugPrint(
                            'ProjectsScreen: Navigating to edit project for ID: ${project.id}');
                        context.push('/project-workspace/${project.id}');
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${_formatDate(project.startDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  if (project.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 16,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'End: ${_formatDate(project.endDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDetails() {
    final project = _projects.firstWhere((p) => p.id == _selectedProjectId);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Header
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
                      color: primaryColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withAlpha(128)),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: primaryColor,
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
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            project.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(230),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${_formatDate(project.startDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  if (project.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 16,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'End: ${_formatDate(project.endDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sprints Section
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sprints',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _navigateToSprintConsole(_selectedProjectId),
                    icon: const Icon(Icons.add),
                    label: const Text('Manage Sprints'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_projectSprints == null) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ] else if (_projectSprints!['sprints'].isEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_run_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sprints for this project',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create sprints to start planning your work',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _projectSprints!['sprints'].length,
                  itemBuilder: (context, index) {
                    final sprint = _projectSprints!['sprints'][index];
                    return _buildSprintCard(sprint);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSprintCard(Map<String, dynamic> sprint) {
    final theme = Theme.of(context);
    final sprintId = (sprint['id'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () =>
              _navigateToSprintConsole(_selectedProjectId, sprintId: sprintId),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSprintStatusColor(sprint['status'] ?? 'planned'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sprint['name'] ?? 'Untitled Sprint',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sprint['description'] != null &&
                        sprint['description'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sprint['description'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (sprint['start_date'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurface.withAlpha(128),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Start: ${_formatDate(DateTime.parse(sprint['start_date']))}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Color _getSprintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      case 'completed':
      case 'done':
        return Colors.green;
      case 'planned':
      case 'to do':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
