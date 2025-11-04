import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sign_off_report.dart';
import '../services/backend_api_service.dart';
import '../services/deliverable_service.dart';
import '../services/sprint_database_service.dart';
import '../services/api_client.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class ReportEditorScreen extends ConsumerStatefulWidget {
  final String? reportId; // null for create, non-null for edit
  final String? deliverableId; // pre-selected deliverable (optional)
  
  const ReportEditorScreen({
    super.key,
    this.reportId,
    this.deliverableId,
  });

  @override
  ConsumerState<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends ConsumerState<ReportEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _knownLimitationsController = TextEditingController();
  final _nextStepsController = TextEditingController();
  
  final BackendApiService _reportService = BackendApiService();
  final DeliverableService _deliverableService = DeliverableService();
  final SprintDatabaseService _sprintService = SprintDatabaseService();
  
  List<dynamic> _deliverables = [];
  List<dynamic> _sprints = [];
  String? _selectedDeliverableId;
  List<String> _selectedSprintIds = [];
  bool _isLoading = false;
  bool _isSaving = false;
  SignOffReport? _existingReport;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load deliverables
      final deliverablesResponse = await _deliverableService.getDeliverables();
      if (deliverablesResponse.isSuccess && deliverablesResponse.data != null) {
        _deliverables = deliverablesResponse.data!['deliverables'] as List;
      }
      
      // Load sprints
      try {
        final sprintsList = await _sprintService.getSprints();
        _sprints = sprintsList;
      } catch (e) {
        debugPrint('Error loading sprints: $e');
      }
      
      // If editing, load existing report
      if (widget.reportId != null) {
        final reportResponse = await _reportService.getSignOffReport(widget.reportId!);
        if (reportResponse.isSuccess && reportResponse.data != null) {
          final data = reportResponse.data!['data'];
          final content = data['content'] as Map<String, dynamic>? ?? {};
          
          setState(() {
            _selectedDeliverableId = data['deliverableId'] as String? ?? data['deliverable_id'] as String?;
            _titleController.text = content['reportTitle'] as String? ?? '';
            _contentController.text = content['reportContent'] as String? ?? '';
            _knownLimitationsController.text = content['knownLimitations'] as String? ?? '';
            _nextStepsController.text = content['nextSteps'] as String? ?? '';
            _selectedSprintIds = (content['sprintIds'] as List?)?.cast<String>() ?? [];
          });
        }
      } else if (widget.deliverableId != null) {
        _selectedDeliverableId = widget.deliverableId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveReport(bool submit) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeliverableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deliverable')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      ApiResponse response;
      
      if (widget.reportId != null) {
        // Update existing report
        response = await _reportService.updateSignOffReport(
          widget.reportId!,
          {
            'report_title': _titleController.text,
            'report_content': _contentController.text,
            if (_selectedSprintIds.isNotEmpty) 'sprint_ids': _selectedSprintIds,
            if (_knownLimitationsController.text.isNotEmpty) 
              'known_limitations': _knownLimitationsController.text,
            if (_nextStepsController.text.isNotEmpty) 
              'next_steps': _nextStepsController.text,
          },
        );
      } else {
        // Create new report
        response = await _reportService.createSignOffReport({
          'deliverable_id': _selectedDeliverableId!,
          'report_title': _titleController.text,
          'report_content': _contentController.text,
          if (_selectedSprintIds.isNotEmpty) 'sprint_ids': _selectedSprintIds,
          if (_knownLimitationsController.text.isNotEmpty) 
            'known_limitations': _knownLimitationsController.text,
          if (_nextStepsController.text.isNotEmpty) 
            'next_steps': _nextStepsController.text,
        });
      }

      if (response.isSuccess) {
        final reportId = widget.reportId ?? response.data!['data']['id'];
        
        // If submitting, submit the report
        if (submit) {
          final submitResponse = await _reportService.submitSignOffReport(reportId);
          if (submitResponse.isSuccess) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report saved but submission failed: ${submitResponse.error}'),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _knownLimitationsController.dispose();
    _nextStepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        actions: [
          if (widget.reportId != null && _existingReport?.status == ReportStatus.draft)
            TextButton.icon(
              onPressed: _isSaving ? null : () => _saveReport(false),
              icon: const Icon(Icons.save),
              label: const Text('Save Draft'),
              style: TextButton.styleFrom(foregroundColor: FlownetColors.electricBlue),
            ),
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveReport(true),
            icon: const Icon(Icons.send),
            label: const Text('Submit'),
            style: TextButton.styleFrom(foregroundColor: FlownetColors.electricBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportId != null ? 'Edit Sign-Off Report' : 'Create Sign-Off Report',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: FlownetColors.pureWhite,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Deliverable Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDeliverableId,
                      decoration: const InputDecoration(
                        labelText: 'Deliverable *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                      ),
                      items: _deliverables.map((d) {
                        return DropdownMenuItem(
                          value: d['id'] as String,
                          child: Text(d['title'] as String? ?? 'Untitled'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDeliverableId = value),
                      validator: (value) => value == null ? 'Please select a deliverable' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sprint Selection (Multi-select)
                    if (_sprints.isNotEmpty) ...[
                      const Text(
                        'Link Sprints (Optional)',
                        style: TextStyle(color: FlownetColors.coolGray, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _sprints.map((sprint) {
                          final sprintId = sprint['id'] as String;
                          final isSelected = _selectedSprintIds.contains(sprintId);
                          return FilterChip(
                            label: Text(sprint['name'] as String? ?? 'Unnamed Sprint'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSprintIds.add(sprintId);
                                } else {
                                  _selectedSprintIds.remove(sprintId);
                                }
                              });
                            },
                            selectedColor: FlownetColors.electricBlue.withValues(alpha: 0.3),
                            checkmarkColor: FlownetColors.electricBlue,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Report Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Report Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Report Content
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Report Content *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
                      validator: (value) => value?.isEmpty == true ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Known Limitations
                    TextFormField(
                      controller: _knownLimitationsController,
                      decoration: const InputDecoration(
                        labelText: 'Known Limitations (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    
                    // Next Steps
                    TextFormField(
                      controller: _nextStepsController,
                      decoration: const InputDecoration(
                        labelText: 'Next Steps (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.arrow_forward),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveReport(false),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Draft'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.graphiteGray,
                            foregroundColor: FlownetColors.pureWhite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveReport(true),
                          icon: const Icon(Icons.send),
                          label: const Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.electricBlue,
                            foregroundColor: FlownetColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

