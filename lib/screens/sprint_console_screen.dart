// ignore_for_file: strict_top_level_inference, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/sprint_database_service.dart';
import '../services/jira_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/sprint_board_widget.dart';
import 'create_sprint_screen.dart';
import 'sprint_board_screen.dart';

class SprintConsoleScreen extends StatefulWidget {
  const SprintConsoleScreen({super.key});

  @override
  State<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends State<SprintConsoleScreen> {
  
  // Data
  final List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _sprints = [];
  List<Map<String, dynamic>> _tickets = [];
  
  // UI State
  bool _isLoading = false;
  String? _selectedProjectKey;
  String? _selectedSprintId;
  
  final SprintDatabaseService _databaseService = SprintDatabaseService();
  
  // ignore: strict_top_level_inference
  get id => null;
  
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
      // Load projects first
      final projects = await _databaseService.getProjects();
      setState(() {
        _projects
          ..clear()
          ..addAll(projects);
      });

      // Load sprints using API service
      final sprints = await ApiService.getSprints();
      setState(() {
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FlownetColors.crimsonRed : FlownetColors.electricBlue,
      ),
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateSprintScreen()),
              );
              if (result == true) {
                // Refresh the sprint list if a new sprint was created
                _loadData();
              }
            },
            icon: const Icon(Icons.add, color: FlownetColors.pureWhite),
            tooltip: 'Create New Sprint',
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
          
          // Projects Section
          _buildProjectsSection(),
          const SizedBox(height: 24),
          
          // Sprints Section
          _buildSprintsSection(),
          
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
                    'Selected project: ${_projects.firstWhere((p) => p['key'] == _selectedProjectKey, orElse: () => {'name': 'Unknown'})['name']}',
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
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600
        ? 1
        : width < 900
            ? 2
            : width < 1200
                ? 3
                : 4;
    final aspectRatio = width < 600 ? 1.3 : 1.5;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final isSelected = _selectedProjectKey == project['key'];
        
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
              onPressed: _showCreateSprintDialog,
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
        if (_sprints.isEmpty)
          _buildEmptyState('No sprints yet', 'Create your first sprint to start planning')
        else
          _buildSprintsList(),
      ],
    );
  }

  Widget _buildSprintsList() {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: _sprints.length,
      itemBuilder: (context, index) {
        final sprint = _sprints[index];
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
                    value: _normalizeSprintStatus(sprint['status']),
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
                  onPressed: () => _viewSprintBoard(sprint),
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
        if (_tickets.isEmpty)
          _buildEmptyState('No tickets yet', 'Create your first ticket to start tracking work')
        else
          _buildTicketsBoard(),
      ],
    );
  }

  Widget _buildTicketsBoard() {
    return SizedBox(
      height: 400,
      child: SprintBoardWidget(
        sprintId: _selectedSprintId ?? '',
        sprintName: _sprints.firstWhere(
          (sprint) => sprint['id'].toString() == _selectedSprintId,
          orElse: () => {'name': 'Unknown Sprint'},
        )['name'] ?? 'Unknown Sprint',
        issues: _tickets.map((ticket) => _mapTicketToIssue(ticket)).toList(),
        onIssueStatusChanged: _handleIssueStatusChange,
      ),
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
    setState(() {
      _selectedProjectKey = project['key'];
      _selectedSprintId = null;
      _tickets.clear();
    });
    debugPrint('🎯 Project selected: ${project['name']} (${project['key']})');
    try {
      GoRouter.of(context).go('/repository/${project['key']}');
    } catch (_) {
      Navigator.of(context).pushNamed('/repository/${project['key']}');
    }
  }

  void _selectSprint(Map<String, dynamic> sprint) {
    _navigateToSprintBoard(sprint);
  }

  String _normalizeSprintStatus(dynamic status) {
    final s = (status ?? '').toString().trim().toLowerCase();
    const allowed = {'planning', 'in_progress', 'completed', 'cancelled'};
    if (allowed.contains(s)) return s;
    if (s == 'inprogress' || s == 'in progress' || s == 'started' || s == 'active') return 'in_progress';
    if (s == 'done' || s == 'complete' || s == 'finished') return 'completed';
    if (s == 'canceled' || s == 'terminated' || s == 'abandoned') return 'cancelled';
    if (s == 'planned' || s == 'planning_phase') return 'planning';
    return 'in_progress';
  }

  void _navigateToSprintBoard(Map<String, dynamic> sprint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SprintBoardScreen(
          sprintId: sprint['id']?.toString() ?? '',
          sprintName: sprint['name'] ?? 'Unknown Sprint',
          projectKey: _selectedProjectKey,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return FlownetColors.electricBlue;
      case 'in_progress':
        return FlownetColors.crimsonRed;
      case 'planning':
        return Colors.orange;
      default:
        return FlownetColors.pureWhite;
    }
  }

  // Dialog methods
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

  Future<void> _updateSprintStatus(String sprintId, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _databaseService.updateSprintStatus(
        sprintId: sprintId,
        status: newStatus,
      );

      if (success) {
        _showSnackBar('Sprint status updated to $newStatus');
        await _loadData(); // Reload data to reflect changes
      } else {
        _showSnackBar('Failed to update sprint status', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error updating sprint status: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewSprintBoard(Map<String, dynamic> sprint) {
    // Navigate to sprint board screen with sprint name
    GoRouter.of(context).go('/sprint-board/${sprint['id']}?name=${Uri.encodeComponent(sprint['name'])}');
  }

  void _viewSprintDetails(Map<String, dynamic> sprint) {
    // Navigate to sprint detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SprintDetailScreen(
          sprintId: sprint['id'].toString(),
          sprintData: sprint,
        ),
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
              await _createSprint(
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

  Future<void> _createSprint(String name, String description, String startDate, String endDate) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create sprint via backend API
      final result = await _databaseService.createSprint(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );

      if (result != null) {
        _showSnackBar('Sprint created successfully!');
        await _loadData(); // Reload sprints
      } else {
        _showSnackBar('Failed to create sprint', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error creating sprint: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateTicketDialog() {
    // Implementation for creating tickets
    _showSnackBar('Create Ticket dialog - Coming soon!');
  }

  Future<void> _createProject(String name, String key, String description) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create project via backend API
      final result = await _databaseService.createProject(
        name: name,
        key: key,
        description: description,
      );

      if (result != null) {
        _showSnackBar('Project created successfully!');
        setState(() {
          _selectedProjectKey = key;
        });
        await _loadData(); // Reload projects
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
  void _handleIssueStatusChange(JiraIssue issue, String newStatus) {
    // Implementation for handling status changes
    _showSnackBar('Status changed to $newStatus');
  }

  // Helper method to map ticket to issue format
  JiraIssue _mapTicketToIssue(Map<String, dynamic> ticket) {
    return JiraIssue(
      id: ticket['id']?.toString() ?? '',
      key: ticket['ticket_key']?.toString() ?? '',
      summary: ticket['summary']?.toString() ?? '',
      description: ticket['description']?.toString(),
      status: ticket['status']?.toString(),
      priority: ticket['priority']?.toString(),
      issueType: ticket['issue_type']?.toString(),
      assignee: ticket['assignee']?.toString(),
      reporter: ticket['assignee']?.toString(), // Use assignee as reporter for now
      created: ticket['created_at'] != null ? DateTime.tryParse(ticket['created_at']) : null,
      updated: ticket['updated_at'] != null ? DateTime.tryParse(ticket['updated_at']) : null,
      labels: [],
    );
  }
  
  // ignore: non_constant_identifier_names
  Widget SprintDetailScreen({required String sprintId, required Map<String, dynamic> sprintData}) {
    return Scaffold(
      appBar: AppBar(
        // ignore: prefer_const_constructors
        title: Text('Sprint Details: ${sprintData['name'] ?? 'Unknown'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sprint ID: $sprintId', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Name: ${sprintData['name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Status: ${sprintData['status'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16)),
            // Add more sprint details as needed
          ],
        ),
      ),
    );
  }
  
  
}
