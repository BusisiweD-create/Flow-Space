import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/deliverable_service.dart';
import '../services/backend_api_service.dart';

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
  final _deliverableService = DeliverableService();
  
  String _priority = 'medium';
  String _status = 'draft';
  DateTime? _dueDate;
  final List<String> _selectedSprints = [];
  List<Map<String, dynamic>> _availableSprints = [];
  bool _isSaving = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      debugPrint('📦 Loading sprints...');
      // Use BackendApiService for sprints
      final backendApiService = BackendApiService();
      final response = await backendApiService.getSprints();
      
      debugPrint('📦 Sprint response: isSuccess=${response.isSuccess}, data=${response.data}');
      
      if (response.isSuccess && response.data != null) {
        List<dynamic> sprintsList = [];
        
        if (response.data is List) {
          sprintsList = response.data as List;
        } else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          sprintsList = data['data'] as List? ?? 
                       data['sprints'] as List? ?? 
                       [];
        }
        
        debugPrint('📦 Parsed sprints list: ${sprintsList.length} items');
        
        setState(() {
          _availableSprints = sprintsList
              .where((s) => s != null) // Filter out nulls
              .map((s) {
                if (s is Map<String, dynamic>) {
                  return s;
                } else if (s is Map) {
                  return Map<String, dynamic>.from(s);
                } else {
                  debugPrint('⚠️ Unexpected sprint type: ${s.runtimeType}');
                  return <String, dynamic>{};
                }
              })
              .where((m) => m.isNotEmpty) // Filter out empty maps
              .toList();
        });
        debugPrint('✅ Loaded ${_availableSprints.length} sprints');
      } else {
        setState(() {
          _availableSprints = [];
        });
        debugPrint('⚠️ No sprints found: ${response.error ?? "Unknown error"}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading sprints: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      setState(() {
        _availableSprints = [];
      });
    }
  }

  Future<void> _generateTitleSuggestion() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'Write a concise professional deliverable title. Max 12 words.'
        },
        {
          'role': 'user',
          'content': 'Description: ${_descriptionController.text}\nPriority: $_priority\nDue: ${_dueDate?.toIso8601String() ?? ''}\nSprints: ${_selectedSprints.join(', ')}'
        }
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.6, maxTokens: 40);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) {
          _titleController.text = content.trim();
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateDescriptionSuggestion() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'Write a clear deliverable description summarizing scope, outcomes, and constraints.'
        },
        {
          'role': 'user',
          'content': 'Title: ${_titleController.text}\nPriority: $_priority\nDue: ${_dueDate?.toIso8601String() ?? ''}\nSprints: ${_selectedSprints.join(', ')}\nDefinition of Done: ${_dodController.text}'
        }
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.7, maxTokens: 160);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) {
          _descriptionController.text = content.trim();
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateDodSuggestion() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'Propose 5-8 acceptance criteria as a checklist, one per line.'
        },
        {
          'role': 'user',
          'content': 'Title: ${_titleController.text}\nDescription: ${_descriptionController.text}'
        }
      ];
      final resp = await BackendApiService().aiChat(messages, temperature: 0.7, maxTokens: 200);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
        final content = (data['content'] ?? (data['data']?['content']))?.toString() ?? '';
        if (content.isNotEmpty) {
          _dodController.text = content.trim();
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isGenerating = false);
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
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      debugPrint('📦 Creating deliverable: ${_titleController.text}');
      
      // Use DeliverableService which handles authentication automatically
      final response = await _deliverableService.createDeliverable(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        definitionOfDone: _dodController.text.isEmpty ? null : _dodController.text,
        priority: _priority,
        status: _status,
        dueDate: _dueDate,
        sprintId: _selectedSprints.isNotEmpty ? _selectedSprints.first : null,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        
        if (response.isSuccess) {
          try {
            Deliverable? created;
            if (response.data is Map<String, dynamic>) {
              final m = response.data as Map<String, dynamic>;
              if (m['deliverable'] is Deliverable) {
                created = m['deliverable'] as Deliverable;
              } else if (m['deliverable'] is Map) {
                created = Deliverable.fromJson(Map<String, dynamic>.from(m['deliverable'] as Map));
              } else if (m['id'] != null) {
                created = Deliverable(
                  id: m['id'].toString(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  definitionOfDone: _dodController.text,
                  priority: _priority,
                  status: _status,
                  dueDate: _dueDate,
                  createdBy: '',
                  assignedTo: null,
                  sprintId: _selectedSprints.isNotEmpty ? _selectedSprints.first : null,
                  createdByName: null,
                  assignedToName: null,
                  sprintName: null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }

              if (created != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Deliverable "${created.title}" created'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                try {
                  GoRouter.of(context).go('/report-editor/${created.id}');
                } catch (_) {
                  Navigator.of(context).pushNamed('/report-editor/${created.id}');
                }
              }
            }

            _titleController.clear();
            _descriptionController.clear();
            _dodController.clear();
            _evidenceLinksController.clear();
            setState(() {
              _dueDate = null;
              _selectedSprints.clear();
            });
          } catch (_) {}
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to create deliverable: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating deliverable: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating deliverable: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isGenerating ? null : _generateTitleSuggestion,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Suggest with AI'),
                ),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isGenerating ? null : _generateDescriptionSuggestion,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Suggest with AI'),
                ),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isGenerating ? null : _generateDodSuggestion,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Suggest with AI'),
                ),
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
                  hintText: 'Demo link, repo, test summary, user guide...',
                ),
                maxLines: 2,
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
                    final idStr = (sprint['id'] ?? '').toString();
                    final isSelected = _selectedSprints.contains(idStr);
                    return CheckboxListTile(
                      title: Text(sprint['name']?.toString() ?? ''),
                      subtitle: Text('${sprint['start_date']} - ${sprint['end_date']}'),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!_selectedSprints.contains(idStr)) {
                              _selectedSprints.add(idStr);
                            }
                          } else {
                            _selectedSprints.remove(idStr);
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
                  onPressed: _isSaving ? null : _saveDeliverable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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
    super.dispose();
  }

}

