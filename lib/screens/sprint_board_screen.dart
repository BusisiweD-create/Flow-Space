import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/sprint_database_service.dart';
import '../services/backend_api_service.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';
import '../services/jira_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/sprint_board_widget.dart';

class SprintBoardScreen extends ConsumerStatefulWidget {
  final String sprintId;
  final String sprintName;
  final String? projectKey;
  
  const SprintBoardScreen({
    super.key,
    required this.sprintId,
    required this.sprintName,
    this.projectKey,
  });

  @override
  ConsumerState<SprintBoardScreen> createState() => _SprintBoardScreenState();
}

class _SprintBoardScreenState extends ConsumerState<SprintBoardScreen> {
  final SprintDatabaseService _databaseService = SprintDatabaseService();
  late RealtimeService _realtime;
  
  // Data
  List<JiraIssue> _issues = [];
  Map<String, dynamic>? _sprintDetails;
  
  // UI State
  bool _isLoading = false;
  bool _isCreatingTicket = false;
  bool _useAiForTicket = false;
  bool _isGeneratingAi = false;

  @override
  void initState() {
    super.initState();
    _loadSprintData();
    _setupRealtime();
  }

  Future<void> _loadSprintData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load sprint details
      final sprintDetails = await _databaseService.getSprintDetails(widget.sprintId);
      setState(() {
        _sprintDetails = sprintDetails;
      });

      // Load sprint tickets
      await _loadSprintTickets();
    } catch (e) {
      _showSnackBar('Error loading sprint data: $e', isError: true);
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
        if (sid == widget.sprintId) {
          _loadSprintTickets();
        }
      } catch (_) {}
    });
    _realtime.on('ticket_updated', (data) {
      try {
        final sid = (data['sprint_id'] ?? data['sprintId'] ?? '').toString();
        if (sid == widget.sprintId) {
          _loadSprintTickets();
        }
      } catch (_) {}
    });
    _realtime.on('ticket_deleted', (data) {
      try {
        final sid = (data['sprint_id'] ?? data['sprintId'] ?? '').toString();
        if (sid == widget.sprintId) {
          _loadSprintTickets();
        }
      } catch (_) {}
    });
  }

  Future<void> _loadSprintTickets() async {
    try {
      final ticketData = await _databaseService.getSprintTickets(widget.sprintId);
      
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
      });
      
      debugPrint('✅ Loaded ${issues.length} tickets for sprint ${widget.sprintId}');
    } catch (e) {
      _showSnackBar('Error loading tickets: $e', isError: true);
    }
  }

  Future<void> _handleIssueStatusChange(JiraIssue issue, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update issue status in database
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
          _showSnackBar('Ticket ${issue.key} moved to $newStatus');
        } else {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Ticket not found', isError: true);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to update ticket status', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error moving ticket: $e', isError: true);
    }
  }

  void _showCreateTicketDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assigneeController = TextEditingController();
    final aiPromptController = TextEditingController();
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
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: _useAiForTicket,
                      onChanged: (v) {
                        setState(() {
                          _useAiForTicket = v;
                        });
                      },
                      title: const Text('Use AI Assistance', style: TextStyle(color: FlownetColors.pureWhite)),
                    ),
                  ),
                ],
              ),
              if (_useAiForTicket) ...[
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
                    onPressed: _isGeneratingAi
                        ? null
                        : () async {
                            setState(() { _isGeneratingAi = true; });
                            try {
                              final backend = BackendApiService();
                              final messages = [
                                {
                                  'role': 'system',
                                  'content': 'You generate concise sprint tickets. Return JSON with keys: title, description.'
                                },
                                {
                                  'role': 'user',
                                  'content': 'Sprint: ${widget.sprintName}. Context: ${_sprintDetails?['description'] ?? ''}. Requirements: ${aiPromptController.text}'.trim()
                                }
                              ];
                              final resp = await backend.aiChat(messages, temperature: 0.4, maxTokens: 256);
                              if (resp.isSuccess && resp.data != null) {
                                final data = resp.data as Map<String, dynamic>;
                                final content = (data['content'] ?? '').toString();
                                String t = '';
                                String d = '';
                                try {
                                  final parsed = content.startsWith('{') ? jsonDecode(content) : null;
                                  if (parsed is Map) {
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
                            setState(() { _isGeneratingAi = false; });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlownetColors.electricBlue,
                      foregroundColor: FlownetColors.pureWhite,
                    ),
                    icon: _isGeneratingAi
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
              backgroundColor: FlownetColors.electricBlue,
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
        _isCreatingTicket = true;
      });

      // Create ticket via backend API
      final response = await _databaseService.createTicket(
        sprintId: widget.sprintId,
        title: title,
        description: description,
        assignee: assignee.isNotEmpty ? assignee : null,
        priority: priority,
        type: type,
      );

      if (response != null) {
        _showSnackBar('✅ Ticket "$title" created successfully!');
        await _loadSprintTickets(); // Refresh tickets
      } else {
        _showSnackBar('❌ Failed to create ticket', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error creating ticket: $e', isError: true);
    } finally {
      setState(() {
        _isCreatingTicket = false;
      });
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
  void dispose() {
    _realtime.offAll('ticket_created');
    _realtime.offAll('ticket_updated');
    _realtime.offAll('ticket_deleted');
    super.dispose();
  }

  Widget _buildSprintHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlownetColors.charcoalBlack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlownetColors.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_run, color: FlownetColors.electricBlue, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sprintName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: FlownetColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_sprintDetails != null) ...[
                      Text(
                        _sprintDetails!['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FlownetColors.pureWhite.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSprintInfoChip(
                              'Status',
                              _sprintDetails!['status'] ?? 'Unknown',
                              _getStatusColor(_sprintDetails!['status']),
                            ),
                            const SizedBox(width: 12),
                            if (_sprintDetails!['start_date'] != null)
                              _buildSprintInfoChip(
                                'Start',
                                _formatDate(_sprintDetails!['start_date']),
                                FlownetColors.electricBlue,
                              ),
                            const SizedBox(width: 12),
                            if (_sprintDetails!['end_date'] != null)
                              _buildSprintInfoChip(
                                'End',
                                _formatDate(_sprintDetails!['end_date']),
                                FlownetColors.crimsonRed,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildSprintStats(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSprintInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprintStats() {
    final totalIssues = _issues.length;
    final completedIssues = _issues.where((issue) => issue.status == 'Done').length;
    final inProgressIssues = _issues.where((issue) => issue.status == 'In Progress').length;
    final progress = totalIssues > 0 ? (completedIssues / totalIssues) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem('Progress', '${progress.toStringAsFixed(1)}%', FlownetColors.electricBlue),
        const SizedBox(height: 8),
        _buildStatItem('Completed', '$completedIssues/$totalIssues', FlownetColors.electricBlue),
        const SizedBox(height: 8),
        _buildStatItem('In Progress', '$inProgressIssues', FlownetColors.crimsonRed),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
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

  Widget _buildEmptyBoard() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
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
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No tickets yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: FlownetColors.pureWhite.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first ticket to start tracking work',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: FlownetColors.pureWhite.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateTicketDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create First Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return FlownetColors.electricBlue;
      case 'completed':
        return Colors.green;
      case 'planning':
        return Colors.orange;
      default:
        return FlownetColors.pureWhite;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final tz = date.toUtc().add(const Duration(hours: 2));
      String two(int n) => n < 10 ? '0$n' : '$n';
      return '${two(tz.day)}/${two(tz.month)}/${tz.year} ${two(tz.hour)}:${two(tz.minute)}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        title: Text('Sprint Board - ${widget.sprintName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sprint-console');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSprintData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTicketDialog,
            tooltip: 'Create Ticket',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FlownetColors.electricBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sprint Header
                  _buildSprintHeader(),
                  const SizedBox(height: 32),
                  
                  // Sprint Board
                  if (_issues.isNotEmpty)
                    SprintBoardWidget(
                      sprintId: widget.sprintId,
                      sprintName: widget.sprintName,
                      issues: _issues,
                      onIssueStatusChanged: _handleIssueStatusChange,
                    )
                  else
                    _buildEmptyBoard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketDialog,
        backgroundColor: FlownetColors.electricBlue,
        foregroundColor: FlownetColors.pureWhite,
        icon: _isCreatingTicket 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.pureWhite),
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isCreatingTicket ? 'Creating...' : 'Create Ticket'),
      ),
    );
  }
}
