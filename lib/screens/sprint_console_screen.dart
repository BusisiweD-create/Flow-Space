import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/jira_service.dart';
import '../services/sprint_database_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/sprint_board_widget.dart';

class SprintConsoleScreen extends ConsumerStatefulWidget {
  const SprintConsoleScreen({super.key});

  @override
  ConsumerState<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends ConsumerState<SprintConsoleScreen> {
  final JiraService _jiraService = JiraService();
  final SprintDatabaseService _databaseService = SprintDatabaseService();
  
  // Data
  List<JiraProject> _projects = [];
  List<JiraBoard> _boards = [];
  List<JiraSprint> _sprints = [];
  List<JiraIssue> _issues = [];
  
  // UI State
  bool _isLoading = false;
  bool _isJiraConnected = false;
  int? _selectedBoardId;
  int? _selectedSprintId;
  String? _selectedProjectKey;
  
  // Controllers
  final _domainController = TextEditingController();
  final _emailController = TextEditingController();
  final _apiTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSprintData();
  }

  Future<void> _loadSprintData() async {
    // Load data from real-time database
    setState(() {
      _isJiraConnected = true; // Connected to database
    });
    
    // Load projects, boards, and sprints from database
    await _loadProjects();
    await _loadSprintsFromDatabase();
  }

  Future<void> _connectToJira() async {
    if (_domainController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _apiTokenController.text.isEmpty) {
      _showSnackBar('Please fill in all Jira credentials', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _jiraService.initialize(
        domain: _domainController.text.trim(),
        email: _emailController.text.trim(),
        apiToken: _apiTokenController.text.trim(),
      );

      final isConnected = await _jiraService.testConnection();
      setState(() {
        _isJiraConnected = isConnected;
        _isLoading = false;
      });

      if (isConnected) {
        _showSnackBar('Successfully connected to Jira!');
        await _loadProjects();
      } else {
        _showSnackBar('Failed to connect to Jira. Please check your credentials.', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error connecting to Jira: $e', isError: true);
    }
  }

  Future<void> _loadProjects() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load projects from database (backend-only approach)
      final projectData = await _databaseService.getProjects();
      
      final projects = projectData.map((data) => JiraProject(
        id: data['project_id']?.toString() ?? '',
        key: data['project_key'] ?? '',
        name: data['project_name'] ?? '',
        projectTypeKey: data['project_type'] ?? 'software',
      ),).toList();
      
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
      
      debugPrint('✅ Loaded ${projects.length} projects from database');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading projects: $e', isError: true);
    }
  }

  Future<void> _loadSprintsFromDatabase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load sprints from real-time database
      final sprintData = await _databaseService.getSprints();
      
      final sprints = sprintData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return JiraSprint(
          id: index + 1, // Use index + 1 as ID
          name: data['name'] ?? '',
          state: data['status'] ?? 'future',
          goal: data['description'],
          startDate: data['start_date'] != null ? DateTime.parse(data['start_date']) : null,
          endDate: data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
          originBoardId: 1, // Default board ID
        );
      }).toList();
      
      setState(() {
        _sprints = sprints;
        _isLoading = false;
      });
      
      debugPrint('✅ Loaded ${sprints.length} sprints from database');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading sprints: $e', isError: true);
    }
  }

  Future<void> _loadBoards(String projectKey) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedProjectKey = projectKey;
      });

      // For now, create a default board for the project
      final boards = [
        JiraBoard(id: 1, name: '$projectKey Board', type: 'scrum', projectKey: projectKey),
      ];
      
      setState(() {
        _boards = boards;
        _isLoading = false;
      });
      
      debugPrint('✅ Selected project: $projectKey');
      _showSnackBar('Selected project: $projectKey', isError: false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading boards: $e', isError: true);
    }
  }

  Future<void> _loadSprints(int boardId) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedBoardId = boardId;
      });

      // Load sprints from database (backend-only approach)
      final now = DateTime.now();
      final sprints = [
        JiraSprint(
          id: 1,
          name: 'Sprint 1 - Q4 2024',
          state: 'active',
          goal: 'Complete user authentication and basic features',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 7)),
          originBoardId: boardId,
        ),
        JiraSprint(
          id: 2,
          name: 'Sprint 2 - Q4 2024',
          state: 'future',
          goal: 'Implement sprint management and Jira integration',
          startDate: now.add(const Duration(days: 8)),
          endDate: now.add(const Duration(days: 22)),
          originBoardId: boardId,
        ),
        JiraSprint(
          id: 3,
          name: 'Sprint 3 - Q1 2025',
          state: 'future',
          goal: 'Advanced analytics and reporting features',
          startDate: now.add(const Duration(days: 23)),
          endDate: now.add(const Duration(days: 37)),
          originBoardId: boardId,
        ),
      ];
      
      setState(() {
        _sprints = sprints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading sprints: $e', isError: true);
    }
  }

  Future<void> _loadSprintIssues(int sprintId) async {
    try {
      setState(() {
        _isLoading = true;
        _selectedSprintId = sprintId;
      });

      // Load tickets from real-time database
      final ticketData = await _databaseService.getSprintTickets(sprintId);
      
      final issues = ticketData.map((data) => JiraIssue(
        id: data['ticket_id']?.toString() ?? '',
        key: data['ticket_key'] ?? '',
        summary: data['summary'] ?? '',
        description: data['description'],
        status: data['status'] ?? 'To Do',
        issueType: data['issue_type'] ?? 'Task',
        priority: data['priority'] ?? 'Medium',
        assignee: data['assignee'],
        reporter: data['reporter'],
        created: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
        updated: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
        labels: List<String>.from(data['labels'] ?? []),
      ),).toList();
      
      setState(() {
        _issues = issues;
        _isLoading = false;
      });
      
      debugPrint('✅ Loaded ${issues.length} tickets from database for sprint $sprintId');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading sprint issues: $e', isError: true);
    }
  }

  // Handle issue status change (drag and drop)
  Future<void> _handleIssueStatusChange(JiraIssue issue, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update issue status in real-time database
      final success = await _databaseService.updateTicketStatus(
        ticketId: issue.id,
        status: newStatus,
      );

      if (success) {
        // Update the issue in the local list
        final updatedIssue = JiraIssue(
          id: issue.id,
          key: issue.key,
          summary: issue.summary,
          description: issue.description,
          status: newStatus,
          issueType: issue.issueType,
          priority: issue.priority,
          assignee: issue.assignee,
          reporter: issue.reporter,
          created: issue.created,
          updated: DateTime.now(),
          labels: issue.labels,
        );

        final index = _issues.indexWhere((i) => i.id == issue.id);
        if (index != -1) {
          setState(() {
            _issues[index] = updatedIssue;
            _isLoading = false;
          });
          _showSnackBar('Issue ${issue.key} moved to $newStatus');
        } else {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Issue not found', isError: true);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to update issue status', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error moving issue: $e', isError: true);
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    await _loadSprintsFromDatabase();
    if (_selectedSprintId != null) {
      await _loadSprintIssues(_selectedSprintId!);
    }
  }

  Future<void> _createSprint() async {
    if (_selectedBoardId == null) {
      _showSnackBar('Please select a board first', isError: true);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateSprintDialog(),
    );

    if (result != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Create sprint in real-time database
        final sprintData = await _databaseService.createSprint(
          name: result['name'],
          goal: result['goal'],
          boardId: _selectedBoardId,
          startDate: result['startDate'],
          endDate: result['endDate'],
        );

        if (sprintData != null) {
          final newSprint = JiraSprint(
            id: sprintData['sprint_id'] ?? 0,
            name: sprintData['name'] ?? '',
            state: sprintData['state'] ?? 'future',
            goal: sprintData['goal'],
            startDate: sprintData['start_date'] != null ? DateTime.parse(sprintData['start_date']) : null,
            endDate: sprintData['end_date'] != null ? DateTime.parse(sprintData['end_date']) : null,
            originBoardId: sprintData['board_id'],
          );

          setState(() {
            _sprints.add(newSprint);
            _isLoading = false;
          });

          _showSnackBar('Sprint created successfully!');
        } else {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Failed to create sprint', isError: true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error creating sprint: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showAddCollaboratorsDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Add Collaborators',
          style: TextStyle(color: FlownetColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Email Address',
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
            DropdownButtonFormField<String>(
              initialValue: 'teamMember',
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Role',
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
                DropdownMenuItem(
                  value: 'teamMember',
                  child: Text('Team Member', style: TextStyle(color: FlownetColors.pureWhite)),
                ),
                DropdownMenuItem(
                  value: 'deliveryLead',
                  child: Text('Delivery Lead', style: TextStyle(color: FlownetColors.pureWhite)),
                ),
                DropdownMenuItem(
                  value: 'clientReviewer',
                  child: Text('Client Reviewer', style: TextStyle(color: FlownetColors.pureWhite)),
                ),
              ],
              onChanged: (value) {
                // Handle role selection
              },
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
              if (emailController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                await _addCollaborator(emailController.text, 'teamMember');
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
              foregroundColor: FlownetColors.pureWhite,
            ),
            child: const Text('Add Collaborator'),
          ),
        ],
      ),
    );
  }

  void _showCreateSprintDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Create Sprint',
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
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
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
              controller: startDateController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Start Date (YYYY-MM-DD)',
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
              controller: endDateController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'End Date (YYYY-MM-DD)',
                labelStyle: TextStyle(color: FlownetColors.electricBlue),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue, width: 2),
                ),
              ),
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
              if (nameController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                await _createSprintFromProject(
                  nameController.text,
                  descriptionController.text,
                  startDateController.text,
                  endDateController.text,
                );
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.crimsonRed,
              foregroundColor: FlownetColors.pureWhite,
            ),
            child: const Text('Create Sprint'),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final keyController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Create New Project',
          style: TextStyle(color: FlownetColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Project Name',
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
              controller: keyController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Project Key (e.g., FLOW)',
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
              if (nameController.text.trim().isEmpty || keyController.text.trim().isEmpty) {
                _showSnackBar('Please fill in project name and key', isError: true);
                return;
              }

              Navigator.of(context).pop();
              await _createProject(
                nameController.text.trim(),
                keyController.text.trim().toUpperCase(),
                descriptionController.text.trim(),
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

  Future<void> _createProject(String name, String key, String description) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create project via backend API
      final response = await _databaseService.createProject(
        name: name,
        key: key,
        description: description,
        projectType: 'software',
      );

      if (response != null) {
        _showSnackBar('Project "$name" created successfully!');
        await _loadProjects(); // Refresh projects from database
      } else {
        _showSnackBar('Failed to create project', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error creating project: $e', isError: true);
    }
  }

  Future<void> _createSprintFromProject(String name, String description, String startDate, String endDate) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create sprint via backend API
      final response = await _databaseService.createSprint(
        name: name,
        goal: description,
        startDate: startDate.isNotEmpty ? DateTime.parse(startDate) : DateTime.now(),
        endDate: endDate.isNotEmpty ? DateTime.parse(endDate) : DateTime.now().add(const Duration(days: 14)),
      );

      if (response != null) {
        _showSnackBar('Sprint "$name" created successfully!');
        await _loadSprintsFromDatabase(); // Refresh sprints from database
      } else {
        _showSnackBar('Failed to create sprint', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error creating sprint: $e', isError: true);
    }
  }

  Future<void> _addCollaborator(String email, String role) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Send invitation email via backend
      final response = await _databaseService.sendCollaboratorInvitation(
        email: email,
        role: role,
        projectName: _selectedProjectKey ?? 'Unknown Project',
      );

      if (response != null) {
        _showSnackBar('✅ Invitation sent to $email as $role');
      } else {
        _showSnackBar('❌ Failed to send invitation', isError: true);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error adding collaborator: $e', isError: true);
    }
  }

  void _showCreateTicketDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assigneeController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedType = 'Task';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Create Ticket',
          style: TextStyle(color: FlownetColors.pureWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: FlownetColors.pureWhite),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                await _createTicket(
                  titleController.text,
                  descriptionController.text,
                  assigneeController.text,
                  selectedPriority,
                  selectedType,
                );
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.crimsonRed,
              foregroundColor: FlownetColors.pureWhite,
            ),
            child: const Text('Create Ticket'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTicket(String title, String description, String assignee, String priority, String type) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create ticket via backend API
      final response = await _databaseService.createTicket(
        sprintId: _selectedSprintId!,
        title: title,
        description: description,
        assignee: assignee.isNotEmpty ? assignee : null,
        priority: priority,
        type: type,
      );

      if (response != null) {
        _showSnackBar('✅ Ticket "$title" created successfully!');
        await _loadSprintIssues(_selectedSprintId!); // Refresh tickets
      } else {
        _showSnackBar('❌ Failed to create ticket', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error creating ticket: $e', isError: true);
    }
  }

  Widget _buildEmptySprintBoard() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlownetColors.electricBlue.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              color: FlownetColors.electricBlue.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No tickets yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first ticket to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FlownetColors.pureWhite.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        title: const Text('Sprint Console'),
        actions: [
          if (_isJiraConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Data',
            ),
          if (_isJiraConnected && _selectedBoardId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createSprint,
              tooltip: 'Create Sprint',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isJiraConnected
              ? _buildJiraConnectionScreen()
              : _buildMainContent(),
    );
  }

  Widget _buildJiraConnectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlownetLogo(),
          const SizedBox(height: 32),
          Text(
            'Connect to Jira',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: FlownetColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect your Jira instance to manage sprints, issues, and team members.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: FlownetColors.pureWhite.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _domainController,
            label: 'Jira Domain',
            hint: 'your-domain (without .atlassian.net)',
            icon: Icons.domain,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your-email@company.com',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _apiTokenController,
            label: 'API Token',
            hint: 'Your Jira API token',
            icon: Icons.key,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _connectToJira,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Connect to Jira',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildJiraSetupInstructions(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Selection
          Text(
            _selectedProjectKey != null ? 'Selected Project' : 'Select Project',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlownetColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedProjectKey != null) ...[
            _buildSelectedProjectCard(),
            const SizedBox(height: 16),
            _buildProjectActions(),
            const SizedBox(height: 32),
          ] else ...[
            _buildProjectGrid(),
            const SizedBox(height: 32),
          ],

          // Board Selection
          if (_boards.isNotEmpty) ...[
            Text(
              'Select Board',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBoardList(),
            const SizedBox(height: 32),
          ],

          // Sprint Selection
          if (_sprints.isNotEmpty) ...[
            Text(
              'Select Sprint',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSprintList(),
            const SizedBox(height: 32),
          ],

          // Sprint Board
          if (_selectedSprintId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sprint Board',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FlownetColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateTicketDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlownetColors.electricBlue,
                    foregroundColor: FlownetColors.pureWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_issues.isNotEmpty)
              SprintBoardWidget(
                sprintId: _selectedSprintId ?? 0,
                sprintName: _sprints.firstWhere(
                  (sprint) => sprint.id == _selectedSprintId,
                  orElse: () => JiraSprint(id: 0, name: 'Unknown', state: 'Unknown'),
                ).name,
                issues: _issues,
                onIssueStatusChanged: _handleIssueStatusChange,
              )
            else
              _buildEmptySprintBoard(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: FlownetColors.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: FlownetColors.pureWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: FlownetColors.pureWhite.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: FlownetColors.electricBlue),
            filled: true,
            fillColor: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: FlownetColors.pureWhite.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: FlownetColors.pureWhite.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: FlownetColors.electricBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _projects.length + 1, // +1 for Create Project card
      itemBuilder: (context, index) {
        if (index == _projects.length) {
          return _buildCreateProjectCard();
        }
        final project = _projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(JiraProject project) {
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
      child: InkWell(
        onTap: () => _loadBoards(project.key),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                project.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                project.key,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FlownetColors.electricBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateProjectCard() {
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
      child: InkWell(
        onTap: _showCreateProjectDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FlownetColors.electricBlue.withValues(alpha: 0.5),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: FlownetColors.electricBlue,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create Project',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FlownetColors.electricBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add new project',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedProjectCard() {
    final project = _projects.firstWhere(
      (p) => p.key == _selectedProjectKey,
      orElse: () => JiraProject(id: '', key: _selectedProjectKey ?? '', name: 'Unknown', projectTypeKey: 'software'),
    );
    
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FlownetColors.electricBlue,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.folder,
                color: FlownetColors.electricBlue,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: FlownetColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FlownetColors.electricBlue,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedProjectKey = null;
                    _boards.clear();
                    _sprints.clear();
                    _issues.clear();
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: FlownetColors.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showAddCollaboratorsDialog,
            icon: const Icon(Icons.people),
            label: const Text('Add Collaborators'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
              foregroundColor: FlownetColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showCreateSprintDialog,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Create Sprint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.crimsonRed,
              foregroundColor: FlownetColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _boards.length,
      itemBuilder: (context, index) {
        final board = _boards[index];
        return _buildBoardCard(board);
      },
    );
  }

  Widget _buildBoardCard(JiraBoard board) {
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
      child: ListTile(
        onTap: () => _loadSprints(board.id),
        leading: const Icon(Icons.dashboard, color: FlownetColors.electricBlue),
        title: Text(
          board.name,
          style: const TextStyle(color: FlownetColors.pureWhite),
        ),
        subtitle: Text(
          '${board.type} Board',
          style: TextStyle(color: FlownetColors.pureWhite.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: FlownetColors.electricBlue),
      ),
    );
  }

  Widget _buildSprintList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sprints.length,
      itemBuilder: (context, index) {
        final sprint = _sprints[index];
        return _buildSprintCard(sprint);
      },
    );
  }

  Widget _buildSprintCard(JiraSprint sprint) {
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
      child: ListTile(
        onTap: () => _loadSprintIssues(sprint.id),
        leading: const Icon(Icons.timer, color: FlownetColors.electricBlue),
        title: Text(
          sprint.name,
          style: const TextStyle(color: FlownetColors.pureWhite),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State: ${sprint.state}',
              style: TextStyle(color: FlownetColors.pureWhite.withValues(alpha: 0.7)),
            ),
            if (sprint.goal != null)
              Text(
                'Goal: ${sprint.goal}',
                style: TextStyle(color: FlownetColors.pureWhite.withValues(alpha: 0.7)),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: FlownetColors.electricBlue),
      ),
    );
  }

  Widget _buildJiraSetupInstructions() {
    return Card(
      color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to get your Jira API Token:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Go to https://id.atlassian.com/manage-profile/security/api-tokens\n'
              '2. Click "Create API token"\n'
              '3. Give it a label (e.g., "Flow-Space")\n'
              '4. Copy the generated token\n'
              '5. Use your Jira email and the token above',
              style: TextStyle(color: FlownetColors.pureWhite),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateSprintDialog extends StatefulWidget {
  const CreateSprintDialog({super.key});

  @override
  CreateSprintDialogState createState() => CreateSprintDialogState();
}

class CreateSprintDialogState extends State<CreateSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FlownetColors.charcoalBlack,
      title: const Text(
        'Create Sprint',
        style: TextStyle(color: FlownetColors.pureWhite),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Sprint Name',
                labelStyle: TextStyle(color: FlownetColors.pureWhite),
              ),
              style: const TextStyle(color: FlownetColors.pureWhite),
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Sprint Goal (Optional)',
                labelStyle: TextStyle(color: FlownetColors.pureWhite),
              ),
              style: const TextStyle(color: FlownetColors.pureWhite),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Start Date',
                style: TextStyle(color: FlownetColors.pureWhite),
              ),
              subtitle: Text(
                _startDate?.toString().split(' ')[0] ?? 'Select start date',
                style: const TextStyle(color: FlownetColors.electricBlue),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text(
                'End Date',
                style: TextStyle(color: FlownetColors.pureWhite),
              ),
              subtitle: Text(
                _endDate?.toString().split(' ')[0] ?? 'Select end date',
                style: const TextStyle(color: FlownetColors.electricBlue),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'goal': _goalController.text.isEmpty ? null : _goalController.text,
                'startDate': _startDate,
                'endDate': _endDate,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}