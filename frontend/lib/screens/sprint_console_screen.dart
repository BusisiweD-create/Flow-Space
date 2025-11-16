// ignore_for_file: unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sprint.dart';

String initialStatusValue(String display) {
  final d = display.toLowerCase();
  if (d.contains('progress')) return 'in_progress';
  if (d.contains('complete')) return 'completed';
  if (d.contains('cancel')) return 'cancelled';
  return 'planning';
}

class SprintConsoleScreen extends ConsumerStatefulWidget {
  const SprintConsoleScreen({super.key});

  @override
  ConsumerState<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends ConsumerState<SprintConsoleScreen> {
  List<Sprint> _sprints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      final sprints = await ApiService.getSprints(limit: 100);
      setState(() {
        _sprints = sprints;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSprint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSprintScreen()),
    );
    if (result == true) {
      _loadSprints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprint Console'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createSprint,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sprints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timeline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No sprints found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first sprint to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createSprint,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Sprint'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sprints.length,
                  itemBuilder: (context, index) {
                    final sprint = _sprints[index];
                    final name = sprint['name']?.toString() ?? 'Unnamed Sprint';
                    final status = sprint['status']?.toString() ?? 'planning';
                    final planned = _toInt(sprint['planned_points'] ?? sprint['plannedPoints']);
                    final completed = _toInt(sprint['completed_points'] ?? sprint['completedPoints']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: planned > 0 ? completed / planned : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_progressColor(completed, planned)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${planned > 0 ? ((completed / planned) * 100).toStringAsFixed(1) : '0.0'}% Complete',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'planning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _progressColor(int completed, int planned) {
    if (planned == 0) return Colors.grey;
    final percentage = completed / planned;
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.8) return Colors.blue;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class CreateSprintScreen extends StatefulWidget {
  const CreateSprintScreen({super.key});

  @override
  State<CreateSprintScreen> createState() => _CreateSprintScreenState();
}

class _CreateSprintScreenState extends State<CreateSprintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plannedPointsController = TextEditingController();
  final _committedPointsController = TextEditingController();
  final _completedPointsController = TextEditingController();
  final _carriedOverPointsController = TextEditingController();
  final _addedDuringSprintController = TextEditingController();
  final _removedDuringSprintController = TextEditingController();
  final _testPassRateController = TextEditingController();
  final _codeCoverageController = TextEditingController();
  final _escapedDefectsController = TextEditingController();
  final _defectsOpenedController = TextEditingController();
  final _defectsClosedController = TextEditingController();
  final _defectSeverityMixController = TextEditingController();
  final _codeReviewCompletionController = TextEditingController();
  final _documentationStatusController = TextEditingController();
  final _uatNotesController = TextEditingController();
  final _uatPassRateController = TextEditingController();
  final _risksIdentifiedController = TextEditingController();
  final _risksMitigatedController = TextEditingController();
  final _blockersController = TextEditingController();
  final _decisionsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 14)) ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _saveSprint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }
    try {
      await ApiService.createSprint(
        name: _nameController.text,
        description: _descriptionController.text,
        startDate: _startDate,
        endDate: _endDate,
        status: 'planning',
        plannedPoints: int.tryParse(_plannedPointsController.text) ?? 0,
        committedPoints: int.tryParse(_plannedPointsController.text) ?? 0,
        completedPoints: int.tryParse(_completedPointsController.text) ?? 0,
        carriedOverPoints: 0,
        addedDuringSprint: 0,
        removedDuringSprint: 0,
        testPassRate: 0,
        codeCoverage: 0,
        escapedDefects: 0,
        defectsOpened: 0,
        defectsClosed: 0,
        defectSeverityMix: null,
        codeReviewCompletion: 0,
        documentationStatus: null,
        uatNotes: null,
        uatPassRate: 0,
        risksIdentified: 0,
        risksMitigated: 0,
        blockers: null,
        decisions: null,
        createdBy: null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sprint created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating sprint: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sprint'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Sprint Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select start date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select end date',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _plannedPointsController,
                      decoration: const InputDecoration(
                        labelText: 'Planned Points',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter planned points';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _completedPointsController,
                      decoration: const InputDecoration(
                        labelText: 'Completed Points',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter completed points';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Quality Metrics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _testPassRateController,
                      decoration: const InputDecoration(
                        labelText: 'Test Pass Rate (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCoverageController,
                      decoration: const InputDecoration(
                        labelText: 'Code Coverage (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _escapedDefectsController,
                      decoration: const InputDecoration(
                        labelText: 'Escaped Defects',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bug_report),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _defectsOpenedController,
                      decoration: const InputDecoration(
                        labelText: 'Defects Opened',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _defectsClosedController,
                      decoration: const InputDecoration(
                        labelText: 'Defects Closed',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _codeReviewCompletionController,
                      decoration: const InputDecoration(
                        labelText: 'Code Review (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.reviews),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defectSeverityMixController,
                decoration: const InputDecoration(
                  labelText: 'Defect Severity Mix',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentationStatusController,
                decoration: const InputDecoration(
                  labelText: 'Documentation Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uatNotesController,
                decoration: const InputDecoration(
                  labelText: 'UAT Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uatPassRateController,
                decoration: const InputDecoration(
                  labelText: 'UAT Pass Rate (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_user),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text(
                'Risk & Decision Tracking',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _risksIdentifiedController,
                      decoration: const InputDecoration(
                        labelText: 'Risks Identified',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _risksMitigatedController,
                      decoration: const InputDecoration(
                        labelText: 'Risks Mitigated',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shield),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _blockersController,
                decoration: const InputDecoration(
                  labelText: 'Blockers',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.block),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _decisionsController,
                decoration: const InputDecoration(
                  labelText: 'Key Decisions',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment_turned_in),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Create Sprint',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _plannedPointsController.dispose();
    _committedPointsController.dispose();
    _completedPointsController.dispose();
    _carriedOverPointsController.dispose();
    _addedDuringSprintController.dispose();
    _removedDuringSprintController.dispose();
    _testPassRateController.dispose();
    _codeCoverageController.dispose();
    _escapedDefectsController.dispose();
    _defectsOpenedController.dispose();
    _defectsClosedController.dispose();
    _defectSeverityMixController.dispose();
    _codeReviewCompletionController.dispose();
    _documentationStatusController.dispose();
    _uatNotesController.dispose();
    _uatPassRateController.dispose();
    _risksIdentifiedController.dispose();
    _risksMitigatedController.dispose();
    _blockersController.dispose();
    _decisionsController.dispose();
    super.dispose();
  }
}