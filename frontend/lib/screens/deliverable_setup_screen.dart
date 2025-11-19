// ignore_for_file: unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sprint.dart';
import '../models/deliverable.dart';

class DeliverableSetupScreen extends ConsumerStatefulWidget {
  const DeliverableSetupScreen({super.key});

  @override
  ConsumerState<DeliverableSetupScreen> createState() => _DeliverableSetupScreenState();
}

class _DeliverableSetupScreenState extends ConsumerState<DeliverableSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dodController = TextEditingController();
  final _evidenceLinksController = TextEditingController();
  final _demoLinkController = TextEditingController();
  final _repoLinkController = TextEditingController();
  final _testSummaryLinkController = TextEditingController();
  final _userGuideLinkController = TextEditingController();
  final _testPassRateController = TextEditingController();
  final _codeCoverageController = TextEditingController();
  final _escapedDefectsController = TextEditingController();
  String _priority = 'medium';
  String _status = 'pending';
  DateTime? _dueDate;
  List<Sprint> _availableSprints = [];
  String? _selectedSprintId;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      final sprints = await ApiService.getSprints(limit: 50);
      setState(() {
        _availableSprints = sprints;
      });
    } catch (_) {}
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _saveDeliverable() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }
    final evidenceLinks = _evidenceLinksController.text
        .split(',')
        .map((link) => link.trim())
        .where((link) => link.isNotEmpty)
        .toList();
    final contributingSprints = _selectedSprintId != null ? [_selectedSprintId!] : <String>[];
    try {
      final dodList = _dodController.text
          .split(RegExp(r'[\n;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final create = DeliverableCreate(
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate!,
        sprintIds: contributingSprints,
        definitionOfDone: dodList,
        evidenceLinks: evidenceLinks,
      );
      await ApiService.createDeliverable(create);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deliverable created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating deliverable: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Deliverable'),
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Deliverable Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dodController,
                decoration: const InputDecoration(
                  labelText: 'Definition of Done',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checklist),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the definition of done';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _priority = value ?? 'medium';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'review', child: Text('Review')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value ?? 'pending';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Select due date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSprintId,
                decoration: const InputDecoration(
                  labelText: 'Contributing Sprint',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                items: [
                  for (final s in _availableSprints)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSprintId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _evidenceLinksController,
                decoration: const InputDecoration(
                  labelText: 'Evidence Links (comma-separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _demoLinkController,
                decoration: const InputDecoration(
                  labelText: 'Demo Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.play_circle),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repoLinkController,
                decoration: const InputDecoration(
                  labelText: 'Repository Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _testSummaryLinkController,
                decoration: const InputDecoration(
                  labelText: 'Test Summary Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userGuideLinkController,
                decoration: const InputDecoration(
                  labelText: 'User Guide Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.library_books),
                ),
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
              TextFormField(
                controller: _escapedDefectsController,
                decoration: const InputDecoration(
                  labelText: 'Escaped Defects',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bug_report),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDeliverable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Create Deliverable',
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
}