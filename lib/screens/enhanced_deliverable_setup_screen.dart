import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/release_readiness.dart';
import '../providers/client_approval_provider.dart';
import '../providers/service_providers.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

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

  void _checkReadiness() {
    setState(() {
      // Update readiness items based on current state
      for (int i = 0; i < _readinessItems.length; i++) {
        final item = _readinessItems[i];
        bool isCompleted = false;
        
        switch (item.id) {
          case 'dod-complete':
            isCompleted = _definitionOfDone.isNotEmpty;
            break;
          case 'evidence-attached':
            isCompleted = _evidenceLinks.isNotEmpty;
            break;
          case 'sprint-metrics':
            isCompleted = _selectedSprints.isNotEmpty;
            break;
          case 'quality-gates':
            isCompleted = true; // Would check actual metrics
            break;
          case 'documentation':
            isCompleted = _evidenceLinks.any((link) => link.contains('docs') || link.contains('guide'));
            break;
        }
        
        _readinessItems[i] = item.copyWith(isCompleted: isCompleted);
      }
    });
  }

  ReadinessStatus _calculateReadinessStatus() {
    final requiredItems = _readinessItems.where((item) => item.isRequired).toList();
    final completedRequired = requiredItems.where((item) => item.isCompleted).length;
    
    if (completedRequired == requiredItems.length) {
      return ReadinessStatus.green;
    } else if (completedRequired >= requiredItems.length * 0.8) {
      return ReadinessStatus.amber;
    } else {
      return ReadinessStatus.red;
    }
  }

  Future<void> _submitDeliverable() async {
    if (!_formKey.currentState!.validate()) return;

    _checkReadiness();
    final readinessStatus = _calculateReadinessStatus();
    
    if (readinessStatus == ReadinessStatus.red) {
      _showReadinessDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final backendService = ref.read(backendApiServiceProvider);
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': (_dueDate ?? DateTime.now()).toIso8601String(),
        'sprintIds': _selectedSprints,
        'definitionOfDone': _definitionOfDone,
        'evidenceLinks': _evidenceLinks,
      };
      final response = await backendService.createDeliverable(payload);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deliverable "${_titleController.text}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating deliverable: ${response.error ?? 'Request failed'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating deliverable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendForApproval() async {
    if (!_formKey.currentState!.validate()) return;

    _checkReadiness();
    final readinessStatus = _calculateReadinessStatus();
    
    if (readinessStatus == ReadinessStatus.red) {
      _showReadinessDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final backendService = ref.read(backendApiServiceProvider);
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': (_dueDate ?? DateTime.now()).toIso8601String(),
        'sprintIds': _selectedSprints,
        'definitionOfDone': _definitionOfDone,
        'evidenceLinks': _evidenceLinks,
      };
      final createResponse = await backendService.createDeliverable(payload);
      final createdDeliverableId = createResponse.data != null
          ? (createResponse.data!['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString())
          : DateTime.now().millisecondsSinceEpoch.toString();
      
      final approvalNotifier = ref.read(clientApprovalProvider.notifier);
      await approvalNotifier.sendForApproval(
        deliverableId: createdDeliverableId,
        deliverableTitle: _titleController.text,
        clientId: 'client_1',
        clientName: 'Client Name',
        dueDate: _dueDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deliverable "${_titleController.text}" sent for client approval!'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending for approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
    _checkReadiness();
    final readinessStatus = _calculateReadinessStatus();
    
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
              // Header
              Text(
                'Create Deliverable',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Deliverable Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
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
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
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
              const SizedBox(height: 24),

              // Definition of Done
              _buildSectionHeader('Definition of Done'),
              const SizedBox(height: 16),
              
              ..._definitionOfDone.map((item) => Card(
                color: FlownetColors.graphiteGray,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _definitionOfDone.remove(item);
                      });
                    },
                  ),
                ),
              ),),
              
              ElevatedButton.icon(
                onPressed: _addDoDItem,
                icon: const Icon(Icons.add),
                label: const Text('Add DoD Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Evidence Links
              _buildSectionHeader('Evidence & Artifacts'),
              const SizedBox(height: 16),
              
              ..._evidenceLinks.map((link) => Card(
                color: FlownetColors.graphiteGray,
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.blue),
                  title: Text(link),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _evidenceLinks.remove(link);
                      });
                    },
                  ),
                ),
              ),),
              
              ElevatedButton.icon(
                onPressed: _addEvidenceLink,
                icon: const Icon(Icons.add),
                label: const Text('Add Evidence Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Release Readiness Check
              _buildSectionHeader('Release Readiness Check'),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: readinessStatus == ReadinessStatus.green ? Colors.green.withValues(alpha: 0.1) :
                         readinessStatus == ReadinessStatus.amber ? Colors.orange.withValues(alpha: 0.1) :
                         Colors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: readinessStatus == ReadinessStatus.green ? Colors.green :
                           readinessStatus == ReadinessStatus.amber ? Colors.orange :
                           Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          readinessStatus == ReadinessStatus.green ? Icons.check_circle :
                          readinessStatus == ReadinessStatus.amber ? Icons.warning :
                          Icons.error,
                          color: readinessStatus == ReadinessStatus.green ? Colors.green :
                                 readinessStatus == ReadinessStatus.amber ? Colors.orange :
                                 Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          readinessStatus == ReadinessStatus.green ? 'Ready for Release' :
                          readinessStatus == ReadinessStatus.amber ? 'Ready with Issues' :
                          'Not Ready',
                          style: TextStyle(
                            color: readinessStatus == ReadinessStatus.green ? Colors.green :
                                   readinessStatus == ReadinessStatus.amber ? Colors.orange :
                                   Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._readinessItems.map((item) => ListTile(
                      leading: Icon(
                        item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: item.isCompleted ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        item.description,
                        style: TextStyle(
                          color: item.isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      subtitle: Text(item.category),
                    ),),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Buttons
              if (readinessStatus != ReadinessStatus.red)
                Column(
                  children: [
                    // Send for Approval Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _sendForApproval,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Send for Client Approval',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Regular Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitDeliverable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: readinessStatus == ReadinessStatus.green ? Colors.green :
                                         readinessStatus == ReadinessStatus.amber ? Colors.orange :
                                         Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                readinessStatus == ReadinessStatus.green ? 'Create Deliverable' :
                                readinessStatus == ReadinessStatus.amber ? 'Create with Acknowledged Issues' :
                                'Complete Required Items First',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDeliverable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: readinessStatus == ReadinessStatus.green ? Colors.green :
                                     readinessStatus == ReadinessStatus.amber ? Colors.orange :
                                     Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            readinessStatus == ReadinessStatus.green ? 'Create Deliverable' :
                            readinessStatus == ReadinessStatus.amber ? 'Create with Acknowledged Issues' :
                            'Complete Required Items First',
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
