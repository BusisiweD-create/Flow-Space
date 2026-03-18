import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sprint_database_service.dart';
import '../widgets/glass_card.dart';
import '../theme/flownet_theme.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _sprints = [];
  List<Map<String, dynamic>> _projectMembers = [];
  String? _error;
  int? _projectDuration;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    try {
      setState(() => _isLoading = true);

      // Load project details - use getProjects and find by ID
      final projectsData = await SprintDatabaseService().getProjects();
      final projectData = projectsData.firstWhere(
        (project) => project['id'] == widget.projectId,
        orElse: () => {},
      );
      
      if (projectData.isNotEmpty) {
        setState(() {
          _project = projectData;
          // Calculate project duration
          if (projectData['start_date'] != null && projectData['end_date'] != null) {
            final startDate = DateTime.parse(projectData['start_date']);
            final endDate = DateTime.parse(projectData['end_date']);
            _projectDuration = endDate.difference(startDate).inDays;
          }
        });

        // Load sprints for this project
        await _loadSprints();
        
        // Load project members
        await _loadProjectMembers();
      } else {
        setState(() => _error = 'Project not found');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load project details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSprints() async {
    try {
      final sprintsData = await SprintDatabaseService().getSprints(projectId: widget.projectId);
      setState(() {
        _sprints = sprintsData;
      });
    } catch (e) {
      debugPrint('Error loading sprints: $e');
    }
  }

  Future<void> _loadProjectMembers() async {
    try {
      // Load real project members from the project data
      if (_project != null && _project!['members'] != null) {
        setState(() {
          _projectMembers = (_project!['members'] as List).map((member) => {
            'id': member['userId'] ?? member['user_id'],
            'name': member['userName'] ?? member['user_name'] ?? 'Unknown',
            'role': member['role'] ?? 'member',
            'email': member['userEmail'] ?? member['user_email'] ?? '',
            'avatar': null,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading project members: $e');
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'planning':
        return 'Planning';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'on_hold':
        return 'On Hold';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return Icons.star;
      case 'manager':
        return Icons.admin_panel_settings;
      case 'developer':
        return Icons.code;
      case 'designer':
        return Icons.palette;
      case 'tester':
        return Icons.bug_report;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'planning':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'on_hold':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.background,
      appBar: AppBar(
        title: Text(_project?['name'] ?? 'Project Details'),
        backgroundColor: FlownetColors.surface,
        foregroundColor: FlownetColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProjectDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _project == null
                  ? const Center(child: Text('Project not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Header
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_project!['status']).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(_project!['status']),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.folder,
                                        color: _getStatusColor(_project!['status']),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _project!['name'] ?? 'Untitled Project',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: FlownetColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _project!['key'] ?? 'NO-KEY',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_project!['description'] != null) ...[
                                  Text(
                                    _project!['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: FlownetColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Row(
                                  children: [
                                    _buildStatusChip(),
                                    const SizedBox(width: 8),
                                    _buildPriorityChip(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Project Metrics
                          Row(
                            children: [
                              Expanded(
                                child: GlassCard(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: FlownetColors.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _projectDuration != null 
                                            ? '$_projectDuration days'
                                            : 'Not set',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: FlownetColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Duration',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GlassCard(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: FlownetColors.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_sprints.length}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: FlownetColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sprints',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GlassCard(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        color: FlownetColors.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_projectMembers.length}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: FlownetColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Members',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Project Timeline
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Project Timeline',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: FlownetColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _project!['start_date'] != null
                                                ? _formatDate(DateTime.parse(_project!['start_date']))
                                                : 'Not set',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: FlownetColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'End Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _project!['end_date'] != null
                                                ? _formatDate(DateTime.parse(_project!['end_date']))
                                                : 'Not set',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: FlownetColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Project Members
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Project Members',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: FlownetColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._projectMembers.map((member) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: FlownetColors.primary.withValues(alpha: 0.1),
                                        child: member['avatar'] != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: Image.network(
                                                  member['avatar'],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                color: FlownetColors.primary,
                                                size: 20,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: FlownetColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              member['role'] ?? 'No role',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _getRoleIcon(member['role']),
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sprints
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Sprints',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: FlownetColors.textPrimary,
                                      ),
                                    ),
                                    if (_sprints.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          // Navigate to sprints screen
                                        },
                                        child: const Text('View All'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_sprints.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            size: 48,
                                            color: Color(0xFFBDBDBD),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No sprints created yet',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ..._sprints.take(3).map((sprint) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: FlownetColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            color: FlownetColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sprint['name'] ?? 'Untitled Sprint',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: FlownetColors.textPrimary,
                                                  ),
                                                ),
                                                if (sprint['start_date'] != null && sprint['end_date'] != null)
                                                  Text(
                                                    '${_formatDate(DateTime.parse(sprint['start_date']))} - ${_formatDate(DateTime.parse(sprint['end_date']))}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(sprint['status']).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColor(sprint['status']),
                                              ),
                                            ),
                                            child: Text(
                                              _formatStatus(sprint['status']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _getStatusColor(sprint['status']),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(_project!['status']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(_project!['status']),
        ),
      ),
      child: Text(
        _formatStatus(_project!['status']),
        style: TextStyle(
          fontSize: 12,
          color: _getStatusColor(_project!['status']),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor(_project!['priority']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityColor(_project!['priority']),
        ),
      ),
      child: Text(
        _formatPriority(_project!['priority']),
        style: TextStyle(
          fontSize: 12,
          color: _getPriorityColor(_project!['priority']),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
