// ignore_for_file: strict_top_level_inference, duplicate_ignore

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/project_card.dart';
import '../services/sprint_database_service.dart';
import 'create_sprint_screen.dart';

class SprintConsoleScreen extends StatefulWidget {
  const SprintConsoleScreen({super.key});

  @override
  State<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends State<SprintConsoleScreen> {
  final SprintDatabaseService _sprintService = SprintDatabaseService();
  // State variables
  final List<Map<String, dynamic>> _projects = [];
  String? _selectedProjectKey;
  String? _selectedSprintId;
  final List<Map<String, dynamic>> _sprints = [];
  final List<Map<String, dynamic>> _tickets = [];
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // Method to show create project dialog
  void _showCreateProjectDialog() {
    final formKey = GlobalKey<FormState>();
    _nameController.clear();
    _keyController.clear();
    _descriptionController.clear();
    final TextEditingController clientEmailController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Project'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,

                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a project name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _keyController,
                        decoration: const InputDecoration(
                          labelText: 'Project Key',
                          hintText: 'e.g., PROJ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a project key';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: clientEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Client Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    startDate = picked;
                                    if (endDate != null && endDate!.isBefore(startDate!)) {
                                      endDate = startDate;
                                    }
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  startDate != null
                                      ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                      : 'Select start date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? (startDate ?? DateTime.now()),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  endDate != null
                                      ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                      : 'Select end date (optional)',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ctx = context;
                if (formKey.currentState!.validate()) {
                  try {
                    final created = await _sprintService.createProject(
                      name: _nameController.text,
                      key: _keyController.text,
                      description: _descriptionController.text,
                      startDate: startDate,
                      endDate: endDate,
                      clientEmail: clientEmailController.text.isNotEmpty
                          ? clientEmailController.text
                          : null,
                    );

                    if (created != null) {
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Project created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (mounted) {
                        await _loadData();
                      }
                    } else if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to create project'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create project: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load projects and sprints using API service
      final projects = await _sprintService.getProjects();
      final sprints = await _sprintService.getSprints();

      setState(() {
        _projects.clear();
        _projects.addAll(projects);
        _sprints.clear();
        _sprints.addAll(sprints);
      });

      // Load tickets if sprint is selected
      if (_selectedSprintId != null) {
        await _loadTickets();
      }
    } catch (e) {
      _showSnackBar('Error loading data: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTickets() async {
    if (_selectedSprintId == null) return;

    try {
      final tickets = await _sprintService.getSprintTickets(_selectedSprintId!);
      setState(() {
        _tickets.clear();
        _tickets.addAll(tickets);
      });
    } catch (e) {
      _showSnackBar('Error loading tickets: $e', isError: true);
    }
  }

  // Helper method to show a snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Handle project selection
  void _selectProject(Map<String, dynamic> project) {
    if (!mounted) return;

    setState(() {
      _selectedProjectKey = project['key']?.toString() ?? project['id']?.toString();
      _selectedSprintId = null; // Reset selected sprint when project changes
      _tickets.clear(); // Clear tickets when project changes
    });

    // Load sprints for the selected project
    _loadSprints(project);
  }

  // Load sprints for a specific project
  Future<void> _loadSprints(Map<String, dynamic> project) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would fetch sprints for the selected project here
      // For now, we'll just use the existing sprints
      setState(() {
        _sprints.clear();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading sprints: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle sprint selection
  void _selectSprint(Map<String, dynamic> sprint) {
    if (!mounted) return;

    setState(() {
      _selectedSprintId = sprint['id']?.toString();
    });

    // Load tickets for the selected sprint
    _loadTickets();

    // Navigate to sprint board (UI navigation only; does not change data logic)
    final sprintId = sprint['id']?.toString();
    if (sprintId != null) {
      final sprintName = sprint['name']?.toString() ?? 'Sprint Board';
      context.push('/sprint-board/$sprintId?name=${Uri.encodeComponent(sprintName)}');
    }
  }

  // Map ticket to issue format
  Map<String, dynamic> _mapTicketToIssue(Map<String, dynamic> ticket) {
    return {
      'id': ticket['id'],
      'key': ticket['key'] ?? 'TKT-${ticket['id']}',
      'fields': {
        'summary': ticket['title'] ?? 'No title',
        'status': {'name': ticket['status'] ?? 'To Do'},
        'priority': {'name': ticket['priority'] ?? 'Medium'},
        'issuetype': {'name': ticket['type'] ?? 'Task'},
      },
    };
  }

  // Update sprint status
  Future<void> _updateSprintStatus(String sprintId, String newStatus) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Find the sprint in the list
      final sprintIndex = _sprints.indexWhere((s) => s['id'].toString() == sprintId);
      if (sprintIndex == -1) return;

      // Update the sprint status locally
      final updatedSprint = Map<String, dynamic>.from(_sprints[sprintIndex]);
      updatedSprint['status'] = newStatus;

      setState(() {
        _sprints[sprintIndex] = updatedSprint;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sprint status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sprint status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        useBackgroundImage: false,
        centered: false,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    return AppScaffold(
      useBackgroundImage: false,
      centered: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Projects Section
          _buildProjectsSection(),
          const SizedBox(height: 24),

          // Sprints Section
          _buildSprintsSection(),
          const SizedBox(height: 24),

          // Tickets Section (conditionally shown when a sprint is selected)
          if (_selectedSprintId != null) ...[
            _buildTicketsSection(),
          ],

          // Add some bottom padding
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return GlassCard(
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
                  Icons.dashboard,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Sprint Management',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your projects, sprints, and tickets in one place',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceColor.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projects',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedProjectKey == null)
                  Text(
                    'Select a project to create sprints',
                    style: TextStyle(
                      color: onSurfaceColor.withAlpha(179),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            GlassButton(
              text: 'Create Project',
              onPressed: _showCreateProjectDialog,
              icon: const Icon(Icons.add, size: 16),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedProjectKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              color: primaryColor.withAlpha(26),
              border: Border.all(color: primaryColor.withAlpha(77)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected project: ${_projects.firstWhere(
                        (p) {
                          final keyOrId =
                              p['key']?.toString() ?? p['id']?.toString();
                          return keyOrId == _selectedProjectKey;
                        },
                        orElse: () => {'name': 'Unknown'},
                      )['name']}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_projects.isEmpty)
          _buildEmptyState(
            'No projects yet',
            'Create your first project to get started',
          )
        else
          _buildProjectsGrid(),
      ],
    );
  }

  Widget _buildProjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            _calculateCrossAxisCount(MediaQuery.of(context).size.width),
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final projectKey =
            project['key']?.toString() ?? project['id']?.toString();
        final isSelected = _selectedProjectKey == projectKey;

        return ProjectCard(
          project: project,
          isSelected: isSelected,
          onTap: () => _selectProject(project),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildSprintsSection() {
    final filteredSprints = _getFilteredSprints();
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sprints',
              style: theme.textTheme.titleLarge?.copyWith(
                color: onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedProjectKey != null
                  ? () async {
                      // Find the selected project by key/id to get its database ID and name
                      final selectedProject = _projects.firstWhere(
                        (p) {
                          final keyOrId =
                              p['key']?.toString() ?? p['id']?.toString();
                          return keyOrId == _selectedProjectKey;
                        },
                        orElse: () => <String, dynamic>{},
                      );

                      final projectId = selectedProject['id']?.toString();
                      final projectName =
                          selectedProject['name']?.toString();

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateSprintScreen(
                            projectId: projectId,
                            projectName: projectName,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Create Sprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredSprints.isEmpty)
          _buildEmptyState(
            _selectedProjectKey != null
                ? 'No sprints for this project'
                : 'No sprints yet',
            _selectedProjectKey != null
                ? 'Create a sprint for the selected project to start planning'
                : 'Create your first sprint to start planning',
          )
        else
          _buildSprintsList(filteredSprints),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredSprints() {
    if (_selectedProjectKey == null) {
      return _sprints;
    }

    final selectedProject = _projects.firstWhere(
      (p) {
        final keyOrId = p['key']?.toString() ?? p['id']?.toString();
        return keyOrId == _selectedProjectKey;
      },
      orElse: () => <String, dynamic>{},
    );

    final selectedProjectId = selectedProject['id']?.toString();
    if (selectedProjectId == null) {
      return _sprints;
    }

    // Filter sprints by selected project and convert to list
    return _sprints.where((sprint) {
      final projectId =
          (sprint['projectId'] ?? sprint['project_id'])?.toString();
      return projectId == selectedProjectId;
    }).toList();
  }

  // Get color based on status
  Color _getStatusColor(String status) {
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

  Widget _buildSprintsList(List<Map<String, dynamic>> sprints) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sprints.length,
      itemBuilder: (context, index) {
        final sprint = sprints[index];
        final isSelected = _selectedSprintId == sprint['id']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(77),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(128),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectSprint(sprint),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Leading icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(51)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(51)
                                    : Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withAlpha(26),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.done : Icons.directions_run,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Sprint details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sprint['name']?.toString() ?? 'Unknown Sprint',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sprint['start_date']?.toString() ?? 'No start date'} - ${sprint['end_date']?.toString() ?? 'No end date'}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(179),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status indicator
                          if (sprint['status'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(sprint['status'])
                                    .withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(sprint['status'])
                                      .withAlpha(77),
                                ),
                              ),
                              child: Text(
                                sprint['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(sprint['status']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'metrics') {
                                context.push('/sprint-metrics/${sprint['id']}');
                              } else {
                                _updateSprintStatus(sprint['id'].toString(), value);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'metrics',
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics, size: 18),
                                    SizedBox(width: 8),
                                    Text('Capture Metrics'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'To Do',
                                child: Text('Mark as To Do'),
                              ),
                              PopupMenuItem(
                                value: 'In Progress',
                                child: Text('Mark as In Progress'),
                              ),
                              PopupMenuItem(
                                value: 'Done',
                                child: Text('Mark as Done'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection() {
    if (_tickets.isEmpty) {
      return _buildEmptyState(
        'No tickets in this sprint',
        'Add tickets to this sprint to start tracking work',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Tickets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tickets.length,
          itemBuilder: (context, index) {
            final ticket = _tickets[index];
            final mappedTicket = _mapTicketToIssue(ticket);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.onSurface.withAlpha(26),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(mappedTicket['fields']['summary'] ?? 'No title'),
                subtitle: Text(mappedTicket['key'] ?? ''),
                onTap: () {
                  // Handle ticket tap
                },
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    // Handle view details
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}