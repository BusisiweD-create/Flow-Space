// ignore_for_file: strict_top_level_inference, duplicate_ignore

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import '../widgets/project_card.dart';
import 'sprint_board_screen.dart';
import '../services/api_service.dart';
import '../services/backend_api_service.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';
import '../services/sprint_database_service.dart';
import '../services/jira_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class SprintConsoleScreen extends StatefulWidget {
  final String? initialProjectKey;
  const SprintConsoleScreen({super.key, this.initialProjectKey});

  @override
  State<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends State<SprintConsoleScreen> {
  final SprintDatabaseService _sprintService = SprintDatabaseService();
  // State variables
  final List<Map<String, dynamic>> _projects = [];
  String? _selectedProjectKey;
  String? _selectedSprintId;
  bool _isAiSuggesting = false;
  bool _useAiForTicket = false;
  final bool _isGeneratingAiTicket = false;
  final GlobalKey _sprintsSectionKey = GlobalKey();

  final List<Map<String, dynamic>> _sprints = [];
  final List<Map<String, dynamic>> _tickets = [];
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  late RealtimeService _realtime;
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
    _selectedProjectKey = widget.initialProjectKey;
    _loadData();
    _setupRealtime();
  }

  @override
  void dispose() {
    try {
      _realtime.offAll('ticket_created');
      _realtime.offAll('ticket_updated');
      _realtime.offAll('ticket_deleted');
    } catch (_) {}
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
      if (_selectedProjectKey == null || _selectedProjectKey!.isEmpty) {
        try { await _sprintService.backfillSprintProjects(); } catch (_) {}
      }
      // Load projects and sprints using SprintDatabaseService
      final projects = await _sprintService.getProjects();
      List<Map<String, dynamic>> sprints;
      if (_selectedProjectKey != null && _selectedProjectKey!.isNotEmpty) {
        final selected = projects.firstWhere(
          (p) {
            final keyOrId = p['key']?.toString() ?? p['id']?.toString();
            return keyOrId == _selectedProjectKey;
          },
          orElse: () => <String, dynamic>{},
        );
        final pid = selected['id']?.toString();
        final pkey = selected['key']?.toString();
        sprints = await _sprintService.getSprints(
          projectId: (pid != null && pid.isNotEmpty) ? pid : null,
          projectKey: (pkey != null && pkey.isNotEmpty) ? pkey : null,
        );
      } else {
        sprints = await _sprintService.getSprints();
      }
      setState(() {
        _projects.clear();
        _projects.addAll(projects);
        _sprints.clear();
        _sprints.addAll(sprints);
      });

      // If a project is preselected, ensure sprints section is visible
      if (_selectedProjectKey != null && _selectedProjectKey!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _sprintsSectionKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              alignment: 0.1,
              duration: const Duration(milliseconds: 300),
            );
          }
        });
      }

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

  void _setupRealtime() {
    _realtime = RealtimeService();
    _realtime.initialize(authToken: AuthService().accessToken);
    _realtime.on('ticket_created', (data) {
      try {
        final sid = (data['sprint_id'] ?? data['sprintId'] ?? '').toString();
        if (sid.isNotEmpty && _selectedSprintId != null && sid == _selectedSprintId) {
          _loadTickets();
        }
      } catch (_) {}
    });
    _realtime.on('ticket_updated', (data) {
      try {
        final sid = (data['sprint_id'] ?? data['sprintId'] ?? '').toString();
        if (sid.isNotEmpty && _selectedSprintId != null && sid == _selectedSprintId) {
          _loadTickets();
        }
      } catch (_) {}
    });
    _realtime.on('ticket_deleted', (data) {
      try {
        final sid = (data['sprint_id'] ?? data['sprintId'] ?? '').toString();
        if (sid.isNotEmpty && _selectedSprintId != null && sid == _selectedSprintId) {
          _loadTickets();
        }
      } catch (_) {}
    });
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

    // Navigate to sprint console with project filter
    final keyOrId = _selectedProjectKey;
    if (keyOrId != null && keyOrId.isNotEmpty) {
      context.go('/sprint-console?projectKey=${Uri.encodeComponent(keyOrId)}');
    } else {
      _loadSprints(project);
    }
  }

  // Load sprints for a specific project
  Future<void> _loadSprints(Map<String, dynamic> project) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projectId = project['id']?.toString();
      final projectKey = project['key']?.toString();

      final fetched = await _sprintService.getSprints(
        projectId: (projectId != null && projectId.isNotEmpty) ? projectId : null,
        projectKey: (projectKey != null && projectKey.isNotEmpty) ? projectKey : null,
      );

      setState(() {
        _sprints
          ..clear()
          ..addAll(fetched);
      });

      // Auto-scroll to sprints section after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _sprintsSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 300),
          );
        }
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
      final auth = AuthService();
      if (auth.isSystemAdmin) {
        _showSnackBar('System admin can view/comment only');
        return;
      }
      if (!(auth.isTeamMember || auth.isDeliveryLead)) {
        _showSnackBar('You do not have permission to update sprint status', isError: true);
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        _isLoading = true;
      });

      final sprintIndex = _sprints.indexWhere((s) => s['id'].toString() == sprintId);
      if (sprintIndex == -1) return;

      final current = Map<String, dynamic>.from(_sprints[sprintIndex]);
      final oldStatus = (current['status'] ?? '').toString();
      final sprintName = (current['name'] ?? '').toString();

      final ok = await _sprintService.updateSprintStatus(
        sprintId: sprintId,
        status: newStatus,
        oldStatus: oldStatus.isEmpty ? null : oldStatus,
        sprintName: sprintName.isEmpty ? null : sprintName,
      );

      if (ok) {
        final updated = Map<String, dynamic>.from(current);
        updated['status'] = newStatus;
        setState(() {
          _sprints[sprintIndex] = updated;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sprint status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update sprint status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
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

  Future<void> _confirmAndDeleteSprint(String sprintId, String sprintName) async {
    if (!mounted) return;
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Delete Sprint'),
            content: Text('Delete "$sprintName"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (result != true) return;

      setState(() { _isLoading = true; });
      final ok = await _sprintService.deleteSprint(sprintId);
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      if (ok) {
        setState(() {
          _sprints.removeWhere((s) => s['id'].toString() == sprintId);
          if (_selectedSprintId == sprintId) _selectedSprintId = null;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Sprint deleted'), backgroundColor: Colors.green),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to delete sprint'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting sprint: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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

          // Projects or Sprints Section
          if (_selectedProjectKey == null) ...[
            _buildProjectsSection(),
          ] else ...[
            _buildSelectedProjectSprintsView(),
          ],
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

  Widget _buildSelectedProjectSprintsView() {
    final selected = _projects.firstWhere(
      (p) {
        final keyOrId = p['key']?.toString() ?? p['id']?.toString();
        return keyOrId == _selectedProjectKey;
      },
      orElse: () => <String, dynamic>{},
    );
    return _buildProjectNestedSprints(selected);
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildProjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(MediaQuery.of(context).size.width),
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final projectKey = project['key']?.toString() ?? project['id']?.toString();
        final isSelected = _selectedProjectKey == projectKey;

        return ProjectCard(
          project: project,
          isSelected: isSelected,
          onTap: () => _selectProject(project),
        );
      },
    );
  }

  Widget _buildProjectNestedSprints(Map<String, dynamic> project) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;
    final projectName = project['name']?.toString() ?? 'Project';
    final projectId = project['id']?.toString();
    final projectKey = project['key']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sprints in $projectName',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateSprintDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Sprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sprints.isEmpty)
          _buildEmptyState(
            'No sprints for this project',
            'Create a sprint for the selected project to start planning',
          )
        else
          _buildSprintsList(
            _sprints.where((s) {
              try {
                final pid = (s['project_id'] ?? s['projectId'] ?? (s['project'] is Map ? s['project']['id'] : null))?.toString();
                final pkey = (s['project_key'] ?? s['projectKey'] ?? (s['project'] is Map ? s['project']['key'] : null))?.toString();
                if (projectId != null && projectId.isNotEmpty && pid == projectId) return true;
                if (projectKey != null && projectKey.isNotEmpty && pkey == projectKey) return true;

                // Heuristic: match by name or description containing project name/key
                final name = (s['name'] ?? '').toString().toLowerCase();
                final desc = (s['description'] ?? '').toString().toLowerCase();
                final pName = projectName.toLowerCase();
                final pKey = (projectKey ?? '').toLowerCase();
                if (pName.isNotEmpty && (name.contains(pName) || desc.contains(pName))) return true;
                if (pKey.isNotEmpty && (name.contains(pKey) || desc.contains(pKey))) return true;
              } catch (_) {}
              return false;
            }).toList(),
          ),
      ],
    );
  }

  

  

  // Get color based on status
  Color getStatusColor(String status) {
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          Flexible(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.end,
                              children: [
                                if (sprint['status'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(sprint['status']).withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: getStatusColor(sprint['status']).withAlpha(77),
                                      ),
                                    ),
                                    child: Text(
                                      sprint['status'].toString().toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: getStatusColor(sprint['status']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    final sid = sprint['id'].toString();
                                    if (value == 'delete') {
                                      _confirmAndDeleteSprint(sid, sprint['name']?.toString() ?? 'Sprint');
                                    } else {
                                      _updateSprintStatus(sid, value);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'To Do',
                                      child: Text('Mark as To Do'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'In Progress',
                                      child: Text('Mark as In Progress'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Done',
                                      child: Text('Mark as Done'),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Sprint'),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                ),
                              ],
                            ),
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

  Future<void> aiSuggestProjectName(TextEditingController nameController, TextEditingController descriptionController) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);
    try {
      final messages = [
        {'role': 'system', 'content': 'Propose a concise professional project name.'},
        {'role': 'user', 'content': 'Description: ${descriptionController.text}'}
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.6, maxTokens: 20);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) nameController.text = content.trim();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isAiSuggesting = false);
    }
  }

  Future<void> aiSuggestProjectKey(TextEditingController nameController, TextEditingController keyController) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);
    try {
      final messages = [
        {'role': 'system', 'content': 'Generate a 2-6 letter uppercase project key derived from the name.'},
        {'role': 'user', 'content': 'Name: ${nameController.text}'}
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.4, maxTokens: 8);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) keyController.text = content.trim().replaceAll(RegExp('[^A-Z]'), '');
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isAiSuggesting = false);
    }
  }

  Future<void> aiSuggestProjectDescription(TextEditingController nameController, TextEditingController descriptionController) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);
    try {
      final messages = [
        {'role': 'system', 'content': 'Write a clear project description with scope and outcomes.'},
        {'role': 'user', 'content': 'Name: ${nameController.text}'}
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.7, maxTokens: 120);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) descriptionController.text = content.trim();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isAiSuggesting = false);
    }
  }

  

  void viewSprintBoard(Map<String, dynamic> sprint) {
    // Navigate to sprint board screen with sprint name
    GoRouter.of(context).go('/sprint-board/${sprint['id']}?name=${Uri.encodeComponent(sprint['name'])}');
  }

  void viewSprintDetails(Map<String, dynamic> sprint) {
    // Navigate to sprint detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SprintBoardScreen(
          sprintId: sprint['id'].toString(),
          sprintName: (sprint['name'] ?? 'Sprint').toString(),
          projectKey: sprint['project_id']?.toString(),
        ),
      ),
    );
  }

  void _showCreateSprintDialog() {
    if (_selectedProjectKey == null) {
      _showSnackBar('Select a project first', isError: true);
      return;
    }
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Create New Sprint',
          style: TextStyle(color: FlownetColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Sprint Name',
                labelStyle: TextStyle(color: FlownetColors.electricBlue),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isAiSuggesting ? null : () => aiSuggestSprintName(nameController),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Suggest with AI'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: FlownetColors.electricBlue),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isAiSuggesting ? null : () => aiSuggestSprintDescription(descriptionController),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Suggest with AI'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startDateController,
                    style: const TextStyle(color: FlownetColors.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      labelStyle: TextStyle(color: FlownetColors.electricBlue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        startDateController.text = date.toIso8601String().split('T')[0];
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: endDateController,
                    style: const TextStyle(color: FlownetColors.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      labelStyle: TextStyle(color: FlownetColors.electricBlue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        endDateController.text = date.toIso8601String().split('T')[0];
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: FlownetColors.pureWhite),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || 
                  startDateController.text.isEmpty || 
                  endDateController.text.isEmpty) {
                _showSnackBar('Please fill in all required fields', isError: true);
                return;
              }

              Navigator.of(context).pop();
              await createSprint(
                nameController.text.trim(),
                descriptionController.text.trim(),
                startDateController.text,
                endDateController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
            ),
            child: const Text(
              'Create',
              style: TextStyle(color: FlownetColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> aiSuggestSprintName(TextEditingController nameController) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);
    try {
      final selectedProject = _projects.firstWhere((p) => p['key'] == _selectedProjectKey, orElse: () => {});
      final projectName = selectedProject['name']?.toString() ?? '';
      final messages = [
        {'role': 'system', 'content': 'Propose a sprint name indicating focus and iteration number.'},
        {'role': 'user', 'content': 'Project: $projectName'}
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.6, maxTokens: 24);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) nameController.text = content.trim();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isAiSuggesting = false);
    }
  }

  Future<void> aiSuggestSprintDescription(TextEditingController descriptionController) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);
    try {
      final messages = [
        {'role': 'system', 'content': 'Write a brief sprint goal and scope summary.'}
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.7, maxTokens: 120);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) descriptionController.text = content.trim();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isAiSuggesting = false);
    }
  }

  Future<void> createSprint(String name, String description, String startDate, String endDate) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final selectedProject = _projects.firstWhere(
        (p) => p['key'] == _selectedProjectKey,
        orElse: () => {},
      );
      final projectId = selectedProject['id']?.toString();

      final parsedStartDate = DateTime.parse(startDate);
      final parsedEndDate = DateTime.parse(endDate);

      final result = await _sprintService.createSprint(
        name: name,
        description: description.isNotEmpty ? description : null,
        startDate: parsedStartDate,
        endDate: parsedEndDate,
        projectId: projectId,
      );

      _showSnackBar('Sprint created successfully!');
      try {
        setState(() {
          final mapResult = result;
          _sprints.insert(0, mapResult);
          _selectedSprintId = mapResult['id']?.toString();
        });
        final id = result['id']?.toString() ?? '';
        final nameArg = Uri.encodeComponent((result['name'] ?? '').toString());
        if (id.isNotEmpty) {
          if (!mounted) return;
          GoRouter.of(context).go('/sprint-board/$id?name=$nameArg');
        } else {
          await _loadData();
        }
      } catch (_) {
        await _loadData();
      }
    } catch (e) {
      _showSnackBar('Error creating sprint: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(26),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(mappedTicket['fields']['summary'] ?? 'No title'),
                subtitle: Text(mappedTicket['key'] ?? ''),
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {},
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  void showCreateTicketDialog() {
    if (_selectedSprintId == null) {
      _showSnackBar('Select a sprint first', isError: true);
      return;
    }
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assigneeController = TextEditingController();
    final aiPromptController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedType = 'Task';

    showDialog(
      context: context,
      builder: (context) {
        bool useAi = _useAiForTicket;
        bool isGenerating = _isGeneratingAiTicket;
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            backgroundColor: FlownetColors.charcoalBlack,
            title: const Text('Create Ticket', style: TextStyle(color: FlownetColors.pureWhite)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          value: useAi,
                          onChanged: (v) { dialogSetState(() { useAi = v; }); setState(() { _useAiForTicket = v; }); },
                          title: const Text('Use AI Assistance', style: TextStyle(color: FlownetColors.pureWhite)),
                        ),
                      ),
                    ],
                  ),
                  if (useAi) ...[
                    TextField(
                      controller: aiPromptController,
                      maxLines: 3,
                      style: const TextStyle(color: FlownetColors.pureWhite),
                      decoration: const InputDecoration(
                        labelText: 'AI Prompt (requirements/context)',
                        labelStyle: TextStyle(color: FlownetColors.electricBlue),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: FlownetColors.electricBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () async {
                                dialogSetState(() { isGenerating = true; });
                                try {
                                  final backend = BackendApiService();
                                  final sprintName = _sprints.firstWhere(
                                    (s) => (s['id']?.toString() ?? '') == _selectedSprintId,
                                    orElse: () => {},
                                  )['name'] ?? '';
                                  final messages = [
                                    { 'role': 'system', 'content': 'Generate a sprint ticket. Return JSON with keys: title, description. Include acceptance criteria as bullet points inside description. Keep language clear and actionable.' },
                                    { 'role': 'user', 'content': 'Sprint: $sprintName. Requirements: ${aiPromptController.text}'.trim() }
                                  ];
                                  final resp = await backend.aiChat(messages, temperature: 0.5, maxTokens: 320);
                                  if (resp.isSuccess && resp.data != null) {
                                    final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
                                    final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
                                    String t = '';
                                    String d = '';
                                    try {
                                      Map<String, dynamic>? parsed;
                                      if (content.trim().startsWith('{')) {
                                        parsed = Map<String, dynamic>.from(jsonDecode(content));
                                      } else if (content.contains('{') && content.contains('}')) {
                                        final start = content.indexOf('{');
                                        final end = content.lastIndexOf('}');
                                        if (start >= 0 && end > start) {
                                          final jsonStr = content.substring(start, end + 1);
                                          parsed = Map<String, dynamic>.from(jsonDecode(jsonStr));
                                        }
                                      }
                                      if (parsed != null) {
                                        t = (parsed['title'] ?? '').toString();
                                        d = (parsed['description'] ?? '').toString();
                                      }
                                    } catch (_) {}
                                    if (t.isEmpty) {
                                      final lines = content.split('\n').where((e) => e.trim().isNotEmpty).toList();
                                      t = lines.isNotEmpty ? lines.first.trim() : 'New Sprint Ticket';
                                      d = lines.skip(1).join('\n').trim();
                                      if (d.isEmpty) d = content.trim();
                                    }
                                    titleController.text = t;
                                    descriptionController.text = d;
                                  }
                                } catch (_) {}
                                dialogSetState(() { isGenerating = false; });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlownetColors.electricBlue,
                          foregroundColor: FlownetColors.pureWhite,
                        ),
                        icon: isGenerating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Generate with AI'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: FlownetColors.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Ticket Title',
                      labelStyle: TextStyle(color: FlownetColors.electricBlue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: FlownetColors.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: FlownetColors.electricBlue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: assigneeController,
                    style: const TextStyle(color: FlownetColors.pureWhite),
                    decoration: const InputDecoration(
                      labelText: 'Assignee Email',
                      labelStyle: TextStyle(color: FlownetColors.electricBlue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPriority,
                          style: const TextStyle(color: FlownetColors.pureWhite),
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            labelStyle: TextStyle(color: FlownetColors.electricBlue),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: FlownetColors.electricBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                            ),
                          ),
                          dropdownColor: FlownetColors.charcoalBlack,
                          items: const [
                            DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'Critical', child: Text('Critical', style: TextStyle(color: FlownetColors.pureWhite))),
                          ],
                          onChanged: (value) => selectedPriority = value ?? 'Medium',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          style: const TextStyle(color: FlownetColors.pureWhite),
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            labelStyle: TextStyle(color: FlownetColors.electricBlue),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: FlownetColors.electricBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                            ),
                          ),
                          dropdownColor: FlownetColors.charcoalBlack,
                          items: const [
                            DropdownMenuItem(value: 'Task', child: Text('Task', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'Bug', child: Text('Bug', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'Story', child: Text('Story', style: TextStyle(color: FlownetColors.pureWhite))),
                            DropdownMenuItem(value: 'Epic', child: Text('Epic', style: TextStyle(color: FlownetColors.pureWhite))),
                          ],
                          onChanged: (value) => selectedType = value ?? 'Task',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                if (useAi && (titleController.text.isEmpty || descriptionController.text.isEmpty)) {
                  dialogSetState(() { isGenerating = true; });
                  try {
                    final backend = BackendApiService();
                    final sprintName = _sprints.firstWhere(
                      (s) => (s['id']?.toString() ?? '') == _selectedSprintId,
                      orElse: () => {},
                    )['name'] ?? '';
                    final messages = [
                      { 'role': 'system', 'content': 'Generate a sprint ticket. Return JSON with keys: title, description. Include acceptance criteria as bullet points inside description. Keep language clear and actionable.' },
                      { 'role': 'user', 'content': 'Sprint: $sprintName. Requirements: ${aiPromptController.text}'.trim() }
                    ];
                    final resp = await backend.aiChat(messages, temperature: 0.5, maxTokens: 320);
                    if (resp.isSuccess && resp.data != null) {
                      final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
                      final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
                      String t = '';
                      String d = '';
                      try {
                        Map<String, dynamic>? parsed;
                        if (content.trim().startsWith('{')) {
                          parsed = Map<String, dynamic>.from(jsonDecode(content));
                        } else if (content.contains('{') && content.contains('}')) {
                          final start = content.indexOf('{');
                          final end = content.lastIndexOf('}');
                          if (start >= 0 && end > start) {
                            final jsonStr = content.substring(start, end + 1);
                            parsed = Map<String, dynamic>.from(jsonDecode(jsonStr));
                          }
                        }
                        if (parsed != null) {
                          t = (parsed['title'] ?? '').toString();
                          d = (parsed['description'] ?? '').toString();
                        }
                      } catch (_) {}
                      if (t.isEmpty) {
                        final lines = content.split('\n').where((e) => e.trim().isNotEmpty).toList();
                        t = lines.isNotEmpty ? lines.first.trim() : 'New Sprint Ticket';
                        d = lines.skip(1).join('\n').trim();
                        if (d.isEmpty) d = content.trim();
                      }
                      if (titleController.text.isEmpty) titleController.text = t;
                      if (descriptionController.text.isEmpty) descriptionController.text = d;
                    }
                  } catch (_) {}
                  dialogSetState(() { isGenerating = false; });
                }
                if (titleController.text.isEmpty) {
                  _showSnackBar('Provide a ticket title (AI can help)', isError: true);
                  return;
                }
                final res = await _sprintService.createTicket(
                  sprintId: _selectedSprintId!,
                  title: titleController.text,
                  description: descriptionController.text,
                  assignee: assigneeController.text.isNotEmpty ? assigneeController.text : null,
                  priority: selectedPriority,
                  type: selectedType,
                );
                if (res != null) {
                  _showSnackBar('Ticket created');
                  await _loadTickets();
                  navigator.pop();
                } else {
                  _showSnackBar('Failed to create ticket', isError: true);
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
              foregroundColor: FlownetColors.pureWhite,
            ),
            child: const Text('Create Ticket'),
          ),
        ],
          ),
        );
      },
    );
  }

  Future<void> createProject(String name, String key, String description) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create project via backend API
      final result = await ApiService.createProject(
        name: name,
        key: key,
        description: description,
      );

      if (result != null) {
        _showSnackBar('Project created successfully!');
        setState(() {
          _selectedProjectKey = key;
        });
        if (!mounted) return;
        try {
          GoRouter.of(context).go('/sprint-console?projectKey=${Uri.encodeComponent(key)}');
        } catch (_) {
          Navigator.of(context).pushNamed('/sprint-console?projectKey=${Uri.encodeComponent(key)}');
        }
        await _loadData();
      } else {
        _showSnackBar('Failed to create project', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error creating project: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Event handlers
  void handleIssueStatusChange(JiraIssue issue, String newStatus) {
    // Implementation for handling status changes
    _showSnackBar('Status changed to $newStatus');
  }




}
 
