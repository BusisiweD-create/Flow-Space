import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../widgets/glass_container.dart';
import '../theme/flownet_theme.dart';

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _selectedProjectId;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tickets = await TicketService.getTickets(projectId: _selectedProjectId);
      final epics = await TicketService.getEpics();
      
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error message
    }
  }

  Future<void> _createTicket() async {
    // Show dialog to create ticket
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text(
          'Create New Ticket',
          style: TextStyle(color: FlownetColors.pureWhite, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => _CreateTicketForm(
            onTicketCreated: (ticket) {
              Navigator.of(context).pop();
              _loadData(); // Refresh the list
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.crimsonRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _createEpic() async {
    // Show dialog to create epic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text(
          'Create New Epic',
          style: TextStyle(color: FlownetColors.pureWhite, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => _CreateEpicForm(
            onEpicCreated: (epic) {
              Navigator.of(context).pop();
              _loadData(); // Refresh the list
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.crimsonRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FlownetColors.charcoalBlack,
              FlownetColors.charcoalBlack.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, color: FlownetColors.crimsonRed, size: 28),
                    const SizedBox(width: 16),
                    const Text(
                      'Jira Board',
                      style: TextStyle(
                        color: FlownetColors.pureWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _createTicket,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Ticket'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.electricBlue,
                            foregroundColor: FlownetColors.pureWhite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _createEpic,
                          icon: const Icon(Icons.dashboard, size: 18),
                          label: const Text('Create Epic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.purple,
                            foregroundColor: FlownetColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(color: FlownetColors.pureWhite, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'backlog', child: Text('Backlog')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterStatus = value!);
                        _loadData();
                      },
                      style: const TextStyle(
                        color: FlownetColors.pureWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tickets List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.crimsonRed),
                        ),
                      )
                    : _tickets.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: FlownetColors.coolGray,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No tickets in backlog',
                                  style: TextStyle(
                                    color: FlownetColors.coolGray,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _createTicket,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Create First Ticket'),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FlownetColors.electricBlue,
                                    foregroundColor: FlownetColors.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = _tickets[index];
                              return _TicketCard(ticket: ticket);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateTicketForm extends StatefulWidget {
  final Function(Ticket) onTicketCreated;

  const _CreateTicketForm({super.key, required this.onTicketCreated});

  @override
  State<_CreateTicketForm> createState() => _CreateTicketFormState();
}

class _CreateTicketFormState extends State<_CreateTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _issueTypeController = TextEditingController(text: 'Task');
  final _priorityController = TextEditingController(text: 'Medium');
  final _assigneeController = TextEditingController();
  String? _selectedProjectId;
  String? _selectedSprintId;
  List<String> _projects = [];
  List<String> _sprints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProjectsAndSprints();
  }

  Future<void> _loadProjectsAndSprints() async {
    // This would normally load from your API
    // For now, using mock data
    setState(() {
      _projects = ['Project Alpha', 'Project Beta', 'Project Gamma'];
      _sprints = ['Sprint 1', 'Sprint 2', 'Sprint 3'];
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ticket = await TicketService.createTicket(
        summary: _summaryController.text,
        description: _descriptionController.text,
        issueType: _issueTypeController.text,
        priority: _priorityController.text,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
        projectId: _selectedProjectId!,
        sprintId: _selectedSprintId,
      );

      widget.onTicketCreated(ticket);
    } catch (e) {
      // Show error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Project Selection
          DropdownButtonFormField<String>(
            value: _selectedProjectId,
            decoration: const InputDecoration(
              labelText: 'Project',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            items: _projects.map((project) => DropdownMenuItem(
              value: project,
              child: Text(project, style: const TextStyle(color: FlownetColors.pureWhite)),
            )).toList(),
            onChanged: (value) => setState(() => _selectedProjectId = value),
          ),
          const SizedBox(height: 16),
          
          // Sprint Selection
          DropdownButtonFormField<String>(
            value: _selectedSprintId,
            decoration: const InputDecoration(
              labelText: 'Sprint (Optional)',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            items: _sprints.map((sprint) => DropdownMenuItem(
              value: sprint,
              child: Text(sprint, style: const TextStyle(color: FlownetColors.pureWhite)),
            )).toList(),
            onChanged: (value) => setState(() => _selectedSprintId = value),
          ),
          const SizedBox(height: 16),
          
          // Summary
          TextFormField(
            controller: _summaryController,
            decoration: const InputDecoration(
              labelText: 'Summary *',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 16),
          
          // Issue Type
          DropdownButtonFormField<String>(
            value: _issueTypeController.text,
            decoration: const InputDecoration(
              labelText: 'Issue Type',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            items: const ['Task', 'Bug', 'Story', 'Improvement'].map((type) => DropdownMenuItem(
              value: type,
              child: Text(type, style: const TextStyle(color: FlownetColors.pureWhite)),
            )).toList(),
            onChanged: (value) => setState(() => _issueTypeController.text = value!),
          ),
          const SizedBox(height: 16),
          
          // Priority
          DropdownButtonFormField<String>(
            value: _priorityController.text,
            decoration: const InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            items: const ['Low', 'Medium', 'High', 'Critical'].map((priority) => DropdownMenuItem(
              value: priority,
              child: Text(priority, style: const TextStyle(color: FlownetColors.pureWhite)),
            )).toList(),
            onChanged: (value) => setState(() => _priorityController.text = value!),
          ),
          const SizedBox(height: 16),
          
          // Assignee
          TextFormField(
            controller: _assigneeController,
            decoration: const InputDecoration(
              labelText: 'Assignee (Email)',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.pureWhite),
                      ),
                    )
                  : const Text('Create Ticket'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateEpicForm extends StatefulWidget {
  final Function(Epic) onEpicCreated;

  const _CreateEpicForm({super.key, required this.onEpicCreated});

  @override
  State<_CreateEpicForm> createState() => _CreateEpicFormState();
}

class _CreateEpicFormState extends State<_CreateEpicForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController(text: '#6F42C1');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final epic = await TicketService.createEpic(
        name: _nameController.text,
        description: _descriptionController.text,
        color: _colorController.text,
      );

      widget.onEpicCreated(epic);
    } catch (e) {
      // Show error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Epic Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Epic Name *',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: FlownetColors.pureWhite),
              border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
            ),
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 16),
          
          // Color Picker
          Row(
            children: [
              const Text('Color:', style: TextStyle(color: FlownetColors.pureWhite)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _colorController.text,
                  decoration: const InputDecoration(
                    labelText: 'Epic Color',
                    labelStyle: TextStyle(color: FlownetColors.pureWhite),
                    border: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.slate)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '#6F42C1', child: Text('Purple', style: TextStyle(color: FlownetColors.pureWhite))),
                    DropdownMenuItem(value: '#28A745', child: Text('Blue', style: TextStyle(color: FlownetColors.pureWhite))),
                    DropdownMenuItem(value: '#DC3545', child: Text('Red', style: TextStyle(color: FlownetColors.pureWhite))),
                    DropdownMenuItem(value: '#007ACC', child: Text('Green', style: TextStyle(color: FlownetColors.pureWhite))),
                    DropdownMenuItem(value: '#FF9800', child: Text('Orange', style: TextStyle(color: FlownetColors.pureWhite))),
                  ],
                  onChanged: (value) => setState(() => _colorController.text = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.purple,
                foregroundColor: FlownetColors.pureWhite,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.pureWhite),
                      ),
                    )
                  : const Text('Create Epic'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;

  const _TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(ticket.priority);
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Priority Indicator
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Ticket Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticket.ticketKey,
                          style: const TextStyle(
                            color: FlownetColors.coolGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ticket.summary,
                            style: const TextStyle(
                              color: FlownetColors.pureWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.issueType,
                      style: TextStyle(
                        color: _ownetColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (ticket.assignee != null) ...[
                      Text(
                        'Assigned to: ${ticket.assignee}',
                        style: const TextStyle(
                          color: FlownetColors.coolGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${ticket.status}',
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          if (ticket.description != null && ticket.description!.isNotEmpty) ...[
            Text(
              ticket.description!,
              style: const TextStyle(
                color: FlownetColors.coolGray,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return FlownetColors.emeraldGreen;
      case 'medium':
        return FlownetColors.amberOrange;
      case 'high':
        return FlownetColors.crimsonRed;
      case 'critical':
        return FlownetColors.purple;
      default:
        return FlownetColors.slate;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return FlownetColors.coolGray;
      case 'in progress':
        return FlownetColors.electricBlue;
      case 'done':
        return FlownetColors.emeraldGreen;
      default:
        return FlownetColors.slate;
    }
  }
}
