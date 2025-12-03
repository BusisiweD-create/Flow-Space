import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/release_readiness.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/ai_readiness_gate_widget.dart';
import '../services/deliverable_service.dart';

class EnhancedDeliverableSetupScreen extends ConsumerStatefulWidget {
  const EnhancedDeliverableSetupScreen({super.key});

  @override
  ConsumerState<EnhancedDeliverableSetupScreen> createState() => _EnhancedDeliverableSetupScreenState();
}

class _EnhancedDeliverableSetupScreenState extends ConsumerState<EnhancedDeliverableSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();
  
  DateTime? _dueDate;
  final List<String> _selectedSprints = [];
  final List<String> _definitionOfDone = [];
  final List<String> _evidenceLinks = [];
  final List<ReadinessItem> _readinessItems = [];
  final DeliverableService _deliverableService = DeliverableService();
  ReadinessStatus _currentReadinessStatus = ReadinessStatus.red;
  bool _hasInternalApproval = false;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeReadinessItems();
  }

  void _initializeReadinessItems() {
    _readinessItems.addAll([
      const ReadinessItem(
        id: 'dod-complete',
        category: 'Definition of Done',
        description: 'All DoD items are completed',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'evidence-attached',
        category: 'Evidence',
        description: 'Demo links, repos, and test summaries are attached',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'sprint-metrics',
        category: 'Sprint Performance',
        description: 'Sprint metrics are captured and reviewed',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'quality-gates',
        category: 'Quality Gates',
        description: 'Test pass rate > 90% and critical defects resolved',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'documentation',
        category: 'Documentation',
        description: 'User guides and technical documentation are complete',
        isRequired: false,
        isCompleted: false,
      ),
    ]);
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

  void _addDoDItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Add Definition of Done Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter DoD item...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _definitionOfDone.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addEvidenceLink() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Add Evidence Link'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter evidence URL...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _evidenceLinks.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _requestInternalApproval(String comment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Request Internal Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You are requesting internal approval to proceed despite readiness issues. '
              'An internal approver will review and decide whether to allow submission.',
            ),
            const SizedBox(height: 16),
            Text(
              comment,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Request Approval'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        _hasInternalApproval = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internal approval requested. You can now proceed with submission.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _submitDeliverable() async {
    // Validate form first - check if form key is initialized
    if (_formKey.currentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Form not initialized. Please refresh the page.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Additional validation: title must not be empty or just whitespace
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Title cannot be empty'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      // Focus on title field
      FocusScope.of(context).requestFocus(FocusNode());
      return;
    }

    // Additional validation: description must not be empty or just whitespace
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Description cannot be empty'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if blocked by readiness gate
    if (_currentReadinessStatus == ReadinessStatus.red && !_hasInternalApproval) {
      _showReadinessDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Use trimmed values
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      debugPrint('📦 Creating deliverable: $title');
      
      // Final validation before API call
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }
      if (description.isEmpty) {
        throw Exception('Description cannot be empty');
      }
      
      // Convert arrays to JSON strings for backend
      // Send definition_of_done as a JSON array (not a joined string)
      // The backend expects JSON format for the JSON column
      
      // Use DeliverableService to create deliverable
      final response = await _deliverableService.createDeliverable(
        title: title,
        description: description.isEmpty ? null : description,
        definitionOfDone: _definitionOfDone.isEmpty ? null : _definitionOfDone,
        priority: 'Medium',
        status: 'Draft',
        dueDate: _dueDate,
        sprintId: _selectedSprints.isNotEmpty ? _selectedSprints.first : null,
      );
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Deliverable "$title" created successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate to dashboard instead of popping (safer)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/dashboard');
              }
            });
          }
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
        setState(() {
          _isSubmitting = false;
        });
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

  void _showReadinessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Release Readiness Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The deliverable is not ready for submission. Please complete the required items:'),
            const SizedBox(height: 16),
            ..._readinessItems.where((item) => item.isRequired && !item.isCompleted).map(
              (item) => ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(item.description),
                subtitle: Text(item.category),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Deliverable',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Deliverable Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (value) {
                  // Trigger rebuild so AI widget can analyze
                  setState(() {});
                  // Trigger AI analysis when title changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && value.trim().isNotEmpty) {
                      setState(() {}); // Force widget rebuild to trigger AI analysis
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
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
                onChanged: (value) {
                  debugPrint('📝 Title changed to: "$value"');
                  // Trigger rebuild so AI widget can analyze
                  setState(() {
                    // Force rebuild with new key
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
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
              const SizedBox(height: 24),

              _buildSectionHeader('Definition of Done'),
              const SizedBox(height: 16),
              ...dodCards,
              ElevatedButton.icon(
                onPressed: _addDoDItem,
                icon: const Icon(Icons.add),
                label: const Text('Add DoD Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Evidence & Artifacts'),
              const SizedBox(height: 16),
              ...evidenceCards,
              ElevatedButton.icon(
                onPressed: _addEvidenceLink,
                icon: const Icon(Icons.add),
                label: const Text('Add Evidence Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              // AI-Powered Release Readiness Gate
              _buildSectionHeader('AI Release Readiness Gate'),
              const SizedBox(height: 16),
              
              Builder(
                builder: (context) {
                  debugPrint('📋 Creating AIReadinessGateWidget with title: "${_titleController.text}"');
                  return AIReadinessGateWidget(
                key: ValueKey('ai-gate-${_titleController.text}-${_definitionOfDone.length}-${_evidenceLinks.length}'),
                deliverableId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                deliverableTitle: _titleController.text,
                deliverableDescription: _descriptionController.text,
                definitionOfDone: _definitionOfDone,
                evidenceLinks: _evidenceLinks,
                sprintIds: _selectedSprints,
                knownLimitations: null,
                onStatusChanged: (status) {
                  setState(() {
                    _currentReadinessStatus = status;
                  });
                },
                onInternalApprovalRequested: (comment) {
                  _requestInternalApproval(comment);
                },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (_currentReadinessStatus == ReadinessStatus.red && !_hasInternalApproval)) 
                      ? null 
                      : _submitDeliverable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentReadinessStatus == ReadinessStatus.green 
                        ? Colors.green 
                        : _currentReadinessStatus == ReadinessStatus.amber 
                            ? Colors.orange 
                            : _hasInternalApproval
                                ? Colors.blue
                                : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentReadinessStatus == ReadinessStatus.green 
                              ? 'Create Deliverable' 
                              : _currentReadinessStatus == ReadinessStatus.amber 
                                  ? 'Create with Acknowledged Issues' 
                                  : _hasInternalApproval
                                      ? 'Create with Internal Approval'
                                      : 'Complete Required Items First',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: FlownetColors.pureWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }
}
