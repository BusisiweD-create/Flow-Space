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
  final _assignedToController = TextEditingController();
  final _demoLinkController = TextEditingController();
  final _repoLinkController = TextEditingController();
  final _testSummaryLinkController = TextEditingController();
  final _userGuideLinkController = TextEditingController();
  final _testPassRateController = TextEditingController();
  final _codeCoverageController = TextEditingController();
  final _escapedDefectsController = TextEditingController();
  
  String _priority = 'medium';
  String _status = 'draft';
  DateTime? _dueDate;
  final List<String> _selectedSprints = [];
  List<Sprint> _availableSprints = [];

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      final sprints = await ApiService.getSprints();
      setState(() {
        _availableSprints = sprints;
      });
    } catch (e) {
      debugPrint('Error loading sprints: $e');
    }
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

    try {
      // Parse evidence links from comma-separated text
      final evidenceLinks = _evidenceLinksController.text
          .split(',')
          .map((link) => link.trim())
          .where((link) => link.isNotEmpty)
          .toList();

      await ApiService.createDeliverable(
        DeliverableCreate(
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate!,
          sprintIds: _selectedSprints,
          definitionOfDone: _dodController.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
          evidenceLinks: evidenceLinks,
        ),
      );

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
              // Title
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

              // Description
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

              // Definition of Done
              TextFormField(
                controller: _dodController,
                decoration: const InputDecoration(
                  labelText: 'Definition of Done',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checklist),
                  hintText: 'Enter the acceptance criteria...',
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

              // Priority and Status Row
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
                          _priority = value!;
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
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'review', child: Text('Review')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Due Date
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

              // Evidence Links
              TextFormField(
                controller: _evidenceLinksController,
                decoration: const InputDecoration(
                  labelText: 'Evidence Links',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'Comma-separated URLs: demo, repo, test summary, user guide...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Assigned To
              TextFormField(
                controller: _assignedToController,
                decoration: const InputDecoration(
                  labelText: 'Assigned To (User ID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter user ID (e.g., 00000000-0000-0000-0000-000000000002)',
                ),
              ),
              const SizedBox(height: 16),

              // Demo Link
              TextFormField(
                controller: _demoLinkController,
                decoration: const InputDecoration(
                  labelText: 'Demo Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_library),
                  hintText: 'URL to demo video or recording',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Repository Link
              TextFormField(
                controller: _repoLinkController,
                decoration: const InputDecoration(
                  labelText: 'Repository Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                  hintText: 'URL to source code repository',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Test Summary Link
              TextFormField(
                controller: _testSummaryLinkController,
                decoration: const InputDecoration(
                  labelText: 'Test Summary Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assessment),
                  hintText: 'URL to test results or coverage report',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // User Guide Link
              TextFormField(
                controller: _userGuideLinkController,
                decoration: const InputDecoration(
                  labelText: 'User Guide Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book),
                  hintText: 'URL to documentation or user guide',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Quality Metrics Section
              const Text(
                'Quality Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),

              // Test Pass Rate
              TextFormField(
                controller: _testPassRateController,
                decoration: const InputDecoration(
                  labelText: 'Test Pass Rate (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                  hintText: '0-100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Code Coverage
              TextFormField(
                controller: _codeCoverageController,
                decoration: const InputDecoration(
                  labelText: 'Code Coverage (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bar_chart),
                  hintText: '0-100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Escaped Defects
              TextFormField(
                controller: _escapedDefectsController,
                decoration: const InputDecoration(
                  labelText: 'Escaped Defects',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bug_report),
                  hintText: 'Number of defects found after release',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Sprint Selection
              const Text(
                'Contributing Sprints',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: _availableSprints.map((sprint) {
                    final isSelected = _selectedSprints.contains(sprint.id);
                    return CheckboxListTile(
                      title: Text(sprint.name),
                      subtitle: Text('${sprint.startDate} - ${sprint.endDate}'),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedSprints.add(sprint.id);
                          } else {
                            _selectedSprints.remove(sprint.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dodController.dispose();
    _evidenceLinksController.dispose();
    _assignedToController.dispose();
    _demoLinkController.dispose();
    _repoLinkController.dispose();
    _testSummaryLinkController.dispose();
    _userGuideLinkController.dispose();
    _testPassRateController.dispose();
    _codeCoverageController.dispose();
    _escapedDefectsController.dispose();
    super.dispose();
  }
}
