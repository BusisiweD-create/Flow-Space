import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      final sprintService = SprintDatabaseService();
      
      // Load project details
      final projects = await sprintService.getProjects();
      final project = projects.firstWhere(
        (p) => p['id']?.toString() == widget.projectId,
        orElse: () => {},
      );
      
      if (project.isNotEmpty) {
        // Calculate project duration
        int? duration;
        if (project['start_date'] != null && project['end_date'] != null) {
          final startDate = DateTime.tryParse(project['start_date'].toString());
          final endDate = DateTime.tryParse(project['end_date'].toString());
          if (startDate != null && endDate != null) {
            duration = endDate.difference(startDate).inDays;
          }
        }
        
        // Load project members from database
        final List<Map<String, dynamic>> members = await sprintService.getProjectMembers(widget.projectId);
        
        // Debug: Print the actual structure of members data
        debugPrint('=== DEBUG: Project Members Data Structure ===');
        for (final member in members) {
          debugPrint('Member data: $member');
        }
        debugPrint('=== END DEBUG ===');
        
        // Check if we have permission issues
        if (members.isEmpty && project['created_by'] != null) {
          const currentUserId = '00356a1b-6e08-44b8-8499-a4491d14e988'; // From logs - your user ID
          final isOwner = project['created_by']?.toString() == currentUserId;
          
          if (!isOwner) {
            setState(() {
              _error = 'You don\'t have permission to view the members of this project. Only project members can view project details.';
              _isLoading = false;
            });
            return;
          }
        }
        
        final sprints = await sprintService.getSprints(projectId: widget.projectId);
        
        setState(() {
          _project = project;
          _sprints = sprints;
          _projectMembers = members;
          _projectDuration = duration;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Project not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading project details: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return FlownetColors.success;
      case 'completed':
        return FlownetColors.blue;
      case 'on_hold':
        return FlownetColors.warning;
      case 'cancelled':
        return FlownetColors.error;
      default:
        return FlownetColors.textSecondary;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Active';
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

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return FlownetColors.purple;
      case 'manager':
        return FlownetColors.blue;
      case 'developer':
        return FlownetColors.success;
      case 'designer':
        return FlownetColors.accent;
      case 'tester':
        return FlownetColors.warning;
      default:
        return FlownetColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
                Color(0xFF533483),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.primary),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
                Color(0xFF533483),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: FlownetColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: FlownetColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FlownetColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/projects'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlownetColors.primary,
                        foregroundColor: FlownetColors.pureWhite,
                      ),
                      child: const Text('Back to Projects'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Make scaffold transparent
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF533483),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 32),
              
              // Project Overview Card
              _buildProjectOverviewCard(),
              const SizedBox(height: 24),
              
              // Project Details Grid
              _buildProjectDetailsGrid(),
              const SizedBox(height: 24),
              
              // Project Members Section
              _buildProjectMembersSection(),
              const SizedBox(height: 24),
              
              // Sprints Section
              _buildSprintsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: FlownetColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Icon(
            Icons.folder_outlined,
            color: FlownetColors.pureWhite,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _project?['name'] ?? 'Unknown Project',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: FlownetColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Project Details',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: FlownetColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/projects'),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: FlownetColors.surfaceLight,
            foregroundColor: FlownetColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectOverviewCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlownetColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Status and Priority Row
          Row(
            children: [
              _buildStatusChip(),
              const SizedBox(width: 12),
              _buildPriorityChip(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          if (_project?['description'] != null && _project!['description'].toString().isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FlownetColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _project!['description'].toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FlownetColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Duration and Client Info
          Row(
            children: [
              if (_projectDuration != null) ...[
                const Icon(Icons.schedule, size: 20, color: FlownetColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '$_projectDuration days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FlownetColors.textSecondary,
                  ),
                ),
              ],
              if (_projectDuration != null && (_project?['clientName'] != null)) const SizedBox(width: 24),
              if (_project?['clientName'] != null) ...[
                const Icon(Icons.business, size: 20, color: FlownetColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _project!['clientName'].toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FlownetColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = _project?['status']?.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusLabel(status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip() {
    final priority = _project?['priority']?.toString() ?? 'medium';
    Color priorityColor;
    String priorityLabel;
    
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = FlownetColors.error;
        priorityLabel = 'High Priority';
        break;
      case 'medium':
        priorityColor = FlownetColors.warning;
        priorityLabel = 'Medium Priority';
        break;
      case 'low':
        priorityColor = FlownetColors.success;
        priorityLabel = 'Low Priority';
        break;
      default:
        priorityColor = FlownetColors.textSecondary;
        priorityLabel = 'Medium Priority';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: priorityColor,
          width: 1,
        ),
      ),
      child: Text(
        priorityLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: priorityColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProjectDetailsGrid() {
    return GlassCard(
      child: Column(
        children: [
          Text(
            'Project Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlownetColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            children: [
              _buildProjectDetailItem(Icons.calendar_today, 'Start Date', _project?['start_date']?.toString() ?? 'N/A'),
              _buildProjectDetailItem(Icons.event, 'End Date', _project?['end_date']?.toString() ?? 'N/A'),
              _buildProjectDetailItem(Icons.schedule, 'Duration', _projectDuration != null ? '$_projectDuration days' : 'N/A'),
              _buildProjectDetailItem(Icons.business, 'Client', _project?['clientName']?.toString() ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FlownetColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FlownetColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FlownetColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectMembersSection() {
    return GlassCard(
      child: Column(
        children: [
          Text(
            'Project Members',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlownetColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_projectMembers.isEmpty) ...[
            Text(
              'No members assigned to this project',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FlownetColors.textSecondary,
              ),
            ),
          ] else ...[
            ..._projectMembers.map((member) {
              final name = member['user_name']?.toString() ?? 
                         member['userName']?.toString() ?? 
                         member['name']?.toString() ?? 
                         member['display_name']?.toString() ?? 
                         'Unknown Member';
              final email = member['user_email']?.toString() ?? 
                          member['userEmail']?.toString() ?? 
                          member['email']?.toString() ?? 
                          'No email';
              final role = member['role']?.toString() ?? 'member';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: Text('$email • $role'),
                trailing: Icon(
                  _getRoleIcon(role),
                  color: _getRoleColor(role),
                  size: 20,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSprintsSection() {
    return GlassCard(
      child: Column(
        children: [
          Text(
            'Sprints',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FlownetColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_sprints.isEmpty) ...[
            Text(
              'No sprints found for this project',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FlownetColors.textSecondary,
              ),
            ),
          ] else ...[
            ..._sprints.map((sprint) {
              final sprintName = sprint['name']?.toString() ?? 'Untitled Sprint';
              final sprintStatus = sprint['status']?.toString() ?? 'unknown';
              final sprintId = sprint['id']?.toString() ?? '';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(sprintStatus),
                  child: const Icon(
                    Icons.directions_run,
                    color: FlownetColors.pureWhite,
                    size: 20,
                  ),
                ),
                title: Text(sprintName),
                subtitle: Text('Status: ${sprintStatus.toUpperCase()}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (sprintId.isNotEmpty) {
                    context.go('/sprint-board/$sprintId');
                  }
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
