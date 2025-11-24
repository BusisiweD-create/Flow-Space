// ignore_for_file: strict_top_level_inference, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import 'create_sprint_screen.dart';
import 'sprint_board_screen.dart';

class SprintConsoleScreen extends StatefulWidget {
  const SprintConsoleScreen({super.key});

  @override
  State<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends State<SprintConsoleScreen> {
  // Controllers for project creation form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Data
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _sprints = [];
  List<Map<String, dynamic>> _tickets = [];
  
  // UI State
  bool _isLoading = false;
  String? _selectedProjectKey;
  String? _selectedSprintId;
  
  // Date picker state
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load projects and sprints using API service
      final projects = await ApiService.getProjects();
      final sprints = await ApiService.getSprints();
      
      setState(() {
        _projects = projects;
        _sprints = sprints;
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
      final tickets = await ApiService.getSprintTickets(_selectedSprintId!);
      setState(() {
        _tickets = tickets;
      });
    } catch (e) {
      _showSnackBar('Error loading tickets: $e', isError: true);
    }
  }

  // Helper method to show a snackbar
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

  // Handle issue status change
  Future<void> _handleIssueStatusChange(String issueId, String newStatus) async {
    if (!mounted) return;
    
    try {
      await ApiService.updateTicketStatus(
        issueId: issueId,
        status: newStatus,
      );
      
      if (!mounted) return;
      setState(() {
        final index = _tickets.indexWhere((ticket) => ticket['id'] == issueId);
        if (index != -1) {
          _tickets[index]['status'] = newStatus;
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update ticket status: $e', isError: true);
      }
    }
  }

  // Helper method to show a date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Show snackbar with message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FlownetColors.crimsonRed : FlownetColors.electricBlue,
      ),
    );
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String description = '';
        String? type;
        String? priority;

        return AlertDialog(
          title: const Text('Create New Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => description = value,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Task', 'Bug', 'Story', 'Epic']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) => type = value,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          ))
                      .toList(),
                  onChanged: (value) => priority = value,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {                
                if (title.isNotEmpty && 
                    description.isNotEmpty && 
                    type != null && 
                    priority != null) {
                  try {
                    // Validate required fields
                    if (_selectedSprintId == null) {
                      throw Exception('Please select a sprint');
                    }
                    if (_selectedProjectKey == null) {
                      throw Exception('Project key is required');
                    }
                    
                    // Store context in a local variable before async operation
                    final currentContext = context;
                    
                    // Create the ticket using your API service
                    final newTicket = await ApiService.createTicket(
                      title: title,
                      description: description,
                      type: type!,
                      priority: priority!,
                      sprintId: _selectedSprintId!,
                      projectKey: _selectedProjectKey!,
                    );
                    
                    // Check if widget is still mounted
                    if (!mounted) return;
                    
                    // Check if ticket was created successfully
                    if (newTicket != null) {
                      // Update the UI with the new ticket
                      setState(() {
                        _tickets.add(newTicket);
                      });
                      
                      // Check mounted again before using context
                      if (!mounted) return;
                      if (currentContext.mounted) {
                        Navigator.of(currentContext).pop();
                        _showSnackBar('Ticket created successfully!');
                      }
                    } else {
                      if (!mounted) return;
                      _showSnackBar('Failed to create ticket', isError: true);
                    }
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar('Error creating ticket: $e', isError: true);
                  }
                } else {
                  _showSnackBar('Please fill in all fields', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const FlownetLogo(),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showCreateProjectDialog,
            icon: const Icon(Icons.add, color: FlownetColors.pureWhite),
            tooltip: 'Create Project',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: FlownetColors.pureWhite),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FlownetColors.electricBlue))
          : _buildBody(),
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
          
          // Sprints Section - Show directly without project requirement
          _buildSprintsSection(),
          const SizedBox(height: 24),
          
          // Projects Section - Always show for creating projects
          _buildProjectsSection(),
          const SizedBox(height: 24),
          
          // Tickets Section
          if (_selectedSprintId != null) _buildTicketsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlownetColors.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlownetColors.electricBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: FlownetColors.electricBlue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Sprint Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your projects, sprints, and tickets in one place',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FlownetColors.pureWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FlownetColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedProjectKey == null)
                  Text(
                    'Select a project to create sprints',
                    style: TextStyle(
                      color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateProjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedProjectKey != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: FlownetColors.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FlownetColors.electricBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: FlownetColors.electricBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected project: ${_projects.firstWhere(
                      (p) {
                        final keyOrId = p['key']?.toString() ?? p['id']?.toString();
                        return keyOrId == _selectedProjectKey;
                      },
                      orElse: () => {'name': 'Unknown'},
                    )['name']}',
                    style: const TextStyle(
                      color: FlownetColors.electricBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_projects.isEmpty)
          _buildEmptyState('No projects yet', 'Create your first project to get started')
        else
          _buildProjectsGrid(),
      ],
    );
  }

  Widget _buildProjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final projectKey = project['key']?.toString() ?? project['id']?.toString();
        final isSelected = _selectedProjectKey == projectKey;
        
        return GestureDetector(
          onTap: () => _selectProject(project),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? FlownetColors.electricBlue.withValues(alpha: 0.2)
                  : FlownetColors.charcoalBlack.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? FlownetColors.electricBlue : FlownetColors.pureWhite.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FlownetColors.electricBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: FlownetColors.electricBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        project['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: FlownetColors.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project['key'] ?? '',
                  style: TextStyle(
                    color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project['project_type'] ?? 'software',
                  style: const TextStyle(
                    color: FlownetColors.electricBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSprintsSection() {
    final filteredSprints = _getFilteredSprints();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sprints',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedProjectKey != null ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateSprintScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              } : null,
              icon: const Icon(Icons.add),
              label: const Text('Create Sprint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.crimsonRed,
                foregroundColor: FlownetColors.pureWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredSprints.isEmpty)
          _buildEmptyState(
            _selectedProjectKey != null ? 'No sprints for this project' : 'No sprints yet',
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

    return _sprints
        .where((s) => s['project_id']?.toString() == selectedProjectId)
        .toList();
  }

  Widget _buildSprintsList(List<Map<String, dynamic>> sprints) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sprints.length,
      itemBuilder: (context, index) {
        final sprint = sprints[index];
        final isSelected = _selectedSprintId == sprint['id'].toString();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _selectSprint(sprint),
            tileColor: isSelected 
                ? FlownetColors.electricBlue.withValues(alpha: 0.2)
                : FlownetColors.charcoalBlack.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? FlownetColors.electricBlue : FlownetColors.pureWhite.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FlownetColors.crimsonRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run,
                color: FlownetColors.crimsonRed,
                size: 20,
              ),
            ),
            title: Text(
              sprint['name'] ?? 'Unknown Sprint',
              style: const TextStyle(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              sprint['description'] ?? 'No description',
              style: TextStyle(
                color: FlownetColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(sprint['status']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(sprint['status']).withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _normalizeStatus(sprint['status']),
                    underline: const SizedBox.shrink(),
                    dropdownColor: FlownetColors.charcoalBlack,
                    style: TextStyle(
                      color: _getStatusColor(sprint['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'planning',
                        child: Text('Planning'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != sprint['status']) {
                        _updateSprintStatus(sprint['id'], newStatus);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // View board button
                IconButton(
                  onPressed: () => _navigateToSprintBoard(sprint),
                  icon: const Icon(
                    Icons.dashboard,
                    color: FlownetColors.electricBlue,
                    size: 20,
                  ),
                  tooltip: 'View Sprint Board',
                ),
                const SizedBox(width: 4),
                // View details button
                IconButton(
                  onPressed: () => _viewSprintDetails(sprint),
                  icon: const Icon(
                    Icons.visibility,
                    color: FlownetColors.electricBlue,
                    size: 20,
                  ),
                  tooltip: 'View Sprint Details',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tickets',
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
        
        // Date range selector
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _selectDate(context, true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _startDate != null 
                      ? 'From: ${DateFormat('MMM dd, yyyy').format(_startDate!)}'
                      : 'Select Start Date',
                  style: const TextStyle(color: FlownetColors.pureWhite),
                ),
              ),
            ),
            const Text('to', style: TextStyle(color: FlownetColors.pureWhite)),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _selectDate(context, false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _endDate != null 
                      ? 'To: ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                      : 'Select End Date',
                  style: const TextStyle(color: FlownetColors.pureWhite),
                ),
              ),
            ),
          ],
        ),
        
        if (_tickets.isEmpty)
          _buildEmptyState('No tickets yet', 'Create a ticket to get started')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _mapTicketToIssue(_tickets[index]);
              return Card(
                color: FlownetColors.charcoalBlack,
                child: ListTile(
                  title: Text(
                    '${ticket['key'] ?? ''} - ${ticket['fields']['summary']}',
                    style: const TextStyle(color: FlownetColors.pureWhite),
                  ),
                  subtitle: Text(
                    'Type: ${ticket['fields']['issuetype']['name']} | ' 
                    'Priority: ${ticket['fields']['priority']['name']}\n'
                    'Status: ${ticket['fields']['status']['name']}',
                    style: TextStyle(
                      color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () {
                    // Handle ticket tap
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleIssueStatusChange(ticket['id'], value),
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
                    ],
                    child: const Icon(Icons.more_vert, color: FlownetColors.pureWhite),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlownetColors.pureWhite.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            color: FlownetColors.pureWhite.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: FlownetColors.pureWhite.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _selectProject(Map<String, dynamic> project) {
    final keyOrId = project['key']?.toString() ?? project['id']?.toString();
    setState(() {
      _selectedProjectKey = keyOrId;
      _selectedSprintId = null; // Reset sprint selection
      _tickets.clear(); // Clear tickets
    });
    debugPrint('🎯 Project selected: ${project['name']} ($keyOrId)');
  }

  void _selectSprint(Map<String, dynamic> sprint) {
    _navigateToSprintBoard(sprint);
  }

  void _navigateToSprintBoard(Map<String, dynamic> sprint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SprintBoardScreen(
          sprintId: sprint['id'],
          sprintName: sprint['name'] ?? 'Unknown Sprint',
          projectKey: _selectedProjectKey,
        ),
      ),
    );
  }

  void _viewSprintDetails(Map<String, dynamic> sprint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FlownetColors.charcoalBlack,
          title: Text(
            sprint['name'] ?? 'Sprint Details',
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Status:', sprint['status']?.toString().toUpperCase() ?? 'N/A',
                    _getStatusColor(sprint['status'])),
                _buildDetailRow('Start Date:', sprint['startDate'] != null 
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(sprint['startDate'])) 
                    : 'Not set'),
                _buildDetailRow('End Date:', sprint['endDate'] != null 
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(sprint['endDate'])) 
                    : 'Not set'),
                if (sprint['goal']?.isNotEmpty ?? false)
                  _buildDetailRow('Goal:', sprint['goal']),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: FlownetColors.electricBlue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: FlownetColors.pureWhite, fontSize: 14, height: 1.4),
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(fontWeight: FontWeight.bold, color: FlownetColors.electricBlue),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? FlownetColors.pureWhite.withValues(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final normalizedStatus = status?.toLowerCase() ?? '';
    switch (normalizedStatus) {
      case 'completed':
      case 'done':
        return FlownetColors.electricBlue;
      case 'in_progress':
      case 'active':
        return FlownetColors.crimsonRed;
      case 'planning':
      case 'planned':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return FlownetColors.pureWhite;
    }
  }

  // Normalize status to valid dropdown values
  // Update sprint status
  Future<void> _updateSprintStatus(String sprintId, String newStatus) async {
    if (!mounted) return;
    
    try {
      final success = await ApiService.updateSprintStatus(sprintId, newStatus);
      if (!mounted) return;
      
      if (success) {
        // Update the local state to reflect the change
        if (mounted) {
          setState(() {
            final sprintIndex = _sprints.indexWhere((s) => s['id'] == sprintId);
            if (sprintIndex != -1) {
              _sprints[sprintIndex]['status'] = newStatus;
            }
          });
          _showSnackBar('Sprint status updated successfully');
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to update sprint status', isError: true);
        }
      }
    } catch (e) {
      debugPrint('Error updating sprint status: $e');
      if (mounted) {
        _showSnackBar('Error updating sprint status', isError: true);
      }
    }
  }

  String _normalizeStatus(String? status) {
    final normalized = status?.toLowerCase() ?? 'planning';
    switch (normalized) {
      case 'planned':
        return 'planning';
      case 'active':
        return 'in_progress';
      case 'planning':
      case 'in_progress':
      case 'completed':
      case 'cancelled':
        return normalized;
      default:
        return 'planning';
    }
  }

  void _showCreateProjectDialog() {
    // Reset form
    _nameController.clear();
    _keyController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Project'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (value.contains(' ')) {
                            return 'Key cannot contain spaces';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            try {
                              final project = await ApiService.createProject(
                                name: _nameController.text.trim(),
                                key: _keyController.text.trim().toUpperCase(),
                                description: _descriptionController.text.trim().isNotEmpty
                                    ? _descriptionController.text.trim()
                                    : null,
                              );

                              if (!context.mounted) return;
                              
                              Navigator.of(context).pop();
                              if (project != null) {
                                _loadData();
                                _showSnackBar('Project created successfully!');
                              } else {
                                _showSnackBar(
                                  'Failed to create project. Please try again.',
                                  isError: true,
                                );
                              }
                            } on Exception catch (e) {
                              if (!mounted) return;
                              _showSnackBar(
                                'Error creating project: $e',
                                isError: true,
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
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
      },
    );
  }
}