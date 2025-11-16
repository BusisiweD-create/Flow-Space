import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _isLoadingDeliverables = false;
  SignOffReport? _existingReport;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load deliverables from backend (real-time data)
      await _loadDeliverables();
      
      // Load sprints
      try {
        final sprintsList = await _sprintService.getSprints();
        _sprints = sprintsList;
      } catch (e) {
        debugPrint('Error loading sprints: $e');
      }
      
      // If editing, load existing report
      if (widget.reportId != null) {
        debugPrint('📋 Loading report for editing: ${widget.reportId}');
        final reportResponse = await _reportService.getSignOffReport(widget.reportId!);
        debugPrint('📋 Report response: success=${reportResponse.isSuccess}, data type=${reportResponse.data?.runtimeType}');
        
        if (reportResponse.isSuccess && reportResponse.data != null) {
          // ApiClient already extracts the 'data' field, so response.data is the report object directly
          // But check if it's nested in a 'data' key or is the report directly
          final data = reportResponse.data is Map && reportResponse.data!['data'] != null
              ? reportResponse.data!['data'] as Map<String, dynamic>
              : reportResponse.data as Map<String, dynamic>;
          
          debugPrint('📋 Report data keys: ${data.keys.toList()}');
          
          // Content can be a Map or JSONB object
          final contentRaw = data['content'];
          final content = contentRaw is Map<String, dynamic>
              ? contentRaw
              : contentRaw is Map
                  ? Map<String, dynamic>.from(contentRaw)
                  : <String, dynamic>{};
          
          debugPrint('📋 Content keys: ${content.keys.toList()}');
          
          setState(() {
            _selectedDeliverableId = data['deliverableId']?.toString() ?? data['deliverable_id']?.toString();
            _titleController.text = content['reportTitle']?.toString() ?? '';
            _contentController.text = content['reportContent']?.toString() ?? '';
            _knownLimitationsController.text = content['knownLimitations']?.toString() ?? '';
            _nextStepsController.text = content['nextSteps']?.toString() ?? '';
            _selectedSprintIds = (content['sprintIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
          });
          
          debugPrint('✅ Report loaded successfully');
        } else {
          debugPrint('❌ Failed to load report: ${reportResponse.error}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load report: ${reportResponse.error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (widget.deliverableId != null) {
        _selectedDeliverableId = widget.deliverableId;
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDeliverables() async {
    setState(() => _isLoadingDeliverables = true);
    debugPrint('📦 Loading deliverables from backend...');
    
    try {
      // Try using DeliverableService first (simpler, more reliable)
      final altResponse = await _deliverableService.getDeliverables();
      if (altResponse.isSuccess && altResponse.data != null) {
        final deliverables = altResponse.data!['deliverables'] as List? ?? [];
        _deliverables = deliverables.map((d) {
          if (d is Map) return d;
          // If it's a Deliverable object, convert to map
          try {
            return {
              'id': d.id?.toString() ?? '',
              'title': d.title?.toString() ?? 'Untitled',
              'description': d.description?.toString(),
              'status': d.status?.toString() ?? 'Draft',
            };
          } catch (e) {
            debugPrint('Error converting deliverable object: $e');
            return {
              'id': '',
              'title': 'Unknown',
              'status': 'Draft',
            };
          }
        }).toList();
        debugPrint('✅ Loaded ${_deliverables.length} deliverables (DeliverableService)');
      } else {
        debugPrint('⚠️ DeliverableService failed, trying BackendApiService...');
        // Fallback to BackendApiService
        try {
          final deliverablesResponse = await _reportService.getDeliverables(
            page: 1,
            limit: 100,
          );
          
          if (deliverablesResponse.isSuccess && deliverablesResponse.data != null) {
            List<dynamic> deliverablesList = [];
            
            if (deliverablesResponse.data is List) {
              deliverablesList = deliverablesResponse.data as List;
            } else if (deliverablesResponse.data is Map) {
              final data = deliverablesResponse.data as Map<String, dynamic>;
              deliverablesList = data['data'] as List? ?? 
                                data['deliverables'] as List? ?? 
                                [];
            }
            
            _deliverables = deliverablesList.map((item) {
              if (item is Map) {
                return item;
              }
              return {
                'id': item['id']?.toString() ?? '',
                'title': item['title']?.toString() ?? 'Untitled',
                'description': item['description']?.toString(),
                'status': item['status']?.toString() ?? 'Draft',
              };
            }).toList();
            
            debugPrint('✅ Loaded ${_deliverables.length} deliverables (BackendApiService)');
          } else {
            _deliverables = [];
            debugPrint('⚠️ No deliverables found: ${deliverablesResponse.error}');
          }
        } catch (e) {
          debugPrint('❌ BackendApiService also failed: $e');
          _deliverables = [];
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading deliverables: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _deliverables = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading deliverables. Please try refreshing.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Refresh',
              textColor: Colors.white,
              onPressed: _loadDeliverables,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDeliverables = false);
      }
    }
  }

  Future<void> _saveReport(bool submit) async {
    debugPrint('🔘 Button clicked: ${submit ? "Submit" : "Save Draft"}');
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check deliverable selection
    if (_selectedDeliverableId == null) {
      debugPrint('❌ No deliverable selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deliverable'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('💾 Starting save operation (submit: $submit)...');

    try {
      debugPrint('📋 Deliverable ID: $_selectedDeliverableId');
      debugPrint('📝 Title: ${_titleController.text}');
      debugPrint('📄 Content length: ${_contentController.text.length}');
      debugPrint('🔄 Is update: ${widget.reportId != null}');
      
      ApiResponse response;
      
      if (widget.reportId != null) {
        // Update existing report
        debugPrint('🔄 Updating existing report: ${widget.reportId}');
        final updateData = {
          'reportTitle': _titleController.text,
          'reportContent': _contentController.text,
          if (_selectedSprintIds.isNotEmpty) 'sprintIds': _selectedSprintIds,
          if (_knownLimitationsController.text.isNotEmpty) 
            'knownLimitations': _knownLimitationsController.text,
          if (_nextStepsController.text.isNotEmpty) 
            'nextSteps': _nextStepsController.text,
        };
        debugPrint('📤 Update payload: $updateData');
        response = await _reportService.updateSignOffReport(
          widget.reportId!,
          updateData,
        );
      } else {
        // Create new report
        debugPrint('✨ Creating new report...');
        final createData = {
          'deliverableId': _selectedDeliverableId!,
          'reportTitle': _titleController.text,
          'reportContent': _contentController.text,
          if (_selectedSprintIds.isNotEmpty) 'sprintIds': _selectedSprintIds,
          if (_knownLimitationsController.text.isNotEmpty) 
            'knownLimitations': _knownLimitationsController.text,
          if (_nextStepsController.text.isNotEmpty) 
            'nextSteps': _nextStepsController.text,
        };
        debugPrint('📤 Create payload: $createData');
        response = await _reportService.createSignOffReport(createData);
      }

      debugPrint('📥 Response received: success=${response.isSuccess}, statusCode=${response.statusCode}');
      if (response.data != null) {
        debugPrint('📦 Response data: ${response.data}');
      }
      if (response.error != null) {
        debugPrint('❌ Response error: ${response.error}');
      }

      if (response.isSuccess) {
        // Extract report ID from response
        String? reportId;
        if (widget.reportId != null) {
          reportId = widget.reportId;
          debugPrint('🆔 Using existing report ID: $reportId');
        } else if (response.data != null) {
          // Try different possible response structures
          // API client already extracts 'data' from backend response
          // Backend returns: { success: true, data: {...} }
          // API client returns: response.data = {...}
          final data = response.data;
          reportId = data?['id']?.toString() ?? 
                     data?['data']?['id']?.toString() ??
                     data?['reportId']?.toString();
          debugPrint('🆔 Extracted report ID from response: $reportId');
          debugPrint('🔍 Response data keys: ${data?.keys.toList()}');
        }
        
        if (reportId == null && submit) {
          // For submit, we need the report ID
          debugPrint('⚠️ Warning: Could not extract report ID, but continuing...');
          // Try to get it from the response structure
          if (response.data != null) {
            final fullData = response.data;
            debugPrint('🔍 Full response structure: $fullData');
          }
        }
        
        // If submitting, submit the report
        if (submit) {
          if (reportId == null) {
            throw Exception('Cannot submit: Report ID is missing from response');
          }
          
          debugPrint('📤 Submitting report: $reportId');
          final submitResponse = await _reportService.submitSignOffReport(reportId);
          debugPrint('📥 Submit response: success=${submitResponse.isSuccess}, error=${submitResponse.error}');
          
          if (submitResponse.isSuccess) {
            debugPrint('✅ Report submitted successfully!');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Report submitted successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pop(context, true);
            }
          } else {
            debugPrint('❌ Submit failed: ${submitResponse.error}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Report saved but submission failed: ${submitResponse.error ?? "Unknown error"}'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          // Just saving as draft
          debugPrint('✅ Report saved as draft successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Report saved successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        debugPrint('❌ Save failed: ${response.error}');
        debugPrint('❌ Status code: ${response.statusCode}');
        if (mounted) {
          final errorMessage = response.error ?? 'Failed to save report';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Error: $errorMessage'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in _saveReport: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error saving report: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        debugPrint('🏁 Save operation completed');
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
              icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FlownetColors.electricBlue,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
              style: TextButton.styleFrom(foregroundColor: FlownetColors.electricBlue),
            ),
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveReport(true),
            icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FlownetColors.electricBlue,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSaving ? 'Submitting...' : 'Submit'),
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
                    _isLoadingDeliverables
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _deliverables.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.warning, color: Colors.orange),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'No deliverables available',
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      TextButton.icon(
                                                        onPressed: _loadDeliverables,
                                                        icon: const Icon(Icons.refresh, size: 16),
                                                        label: const Text('Refresh'),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.orange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : DropdownButtonFormField<String>(
                                            initialValue: _selectedDeliverableId,
                                            decoration: const InputDecoration(
                                              labelText: 'Deliverable *',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.assignment),
                                              helperText: 'Select a deliverable to link this report to',
                                            ),
                                            items: _deliverables.map<DropdownMenuItem<String>>((d) {
                                              final id = d is Map ? (d['id'] as String?) : (d.id?.toString() ?? '');
                                              final title = d is Map 
                                                  ? (d['title'] as String? ?? 'Untitled')
                                                  : (d.title?.toString() ?? 'Untitled');
                                              final status = d is Map 
                                                  ? (d['status'] as String? ?? '')
                                                  : (d.status?.toString() ?? '');
                                              
                                              return DropdownMenuItem<String>(
                                                value: id,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    if (status.isNotEmpty)
                                                      Text(
                                                        'Status: $status',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedDeliverableId = value;
                                                debugPrint('📋 Deliverable selected: $value');
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a deliverable';
                                              }
                                              return null;
                                            },
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  context.go('/deliverable-setup');
                                },
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: const Text('Create a new deliverable'),
                                style: TextButton.styleFrom(
                                  foregroundColor: FlownetColors.electricBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Need to create a deliverable? Go to the Deliverable Setup page.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
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
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveReport(false),
                          icon: _isSaving 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.graphiteGray,
                            foregroundColor: FlownetColors.pureWhite,
                            disabledBackgroundColor: FlownetColors.graphiteGray.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _saveReport(true),
                          icon: _isSaving 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(_isSaving ? 'Submitting...' : 'Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlownetColors.electricBlue,
                            foregroundColor: FlownetColors.pureWhite,
                            disabledBackgroundColor: FlownetColors.electricBlue.withValues(alpha: 0.5),
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

