import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/sign_off_report.dart';
import '../models/repository_file.dart';
import '../models/user_role.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../services/sign_off_report_service.dart';
import '../services/report_export_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/document_preview_widget.dart';
import '../widgets/audit_history_widget.dart';
import 'report_editor_screen.dart';
import 'client_review_workflow_screen.dart';

class ReportRepositoryScreen extends ConsumerStatefulWidget {
  const ReportRepositoryScreen({super.key});

  @override
  ConsumerState<ReportRepositoryScreen> createState() => _ReportRepositoryScreenState();
}

class _ReportRepositoryScreenState extends ConsumerState<ReportRepositoryScreen> {
  List<SignOffReport> _reports = [];
  List<RepositoryFile> _reportDocuments = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final DocumentService _documentService = DocumentService(AuthService());
  final SignOffReportService _reportService = SignOffReportService(AuthService());
  final ReportExportService _exportService = ReportExportService();

  @override
  void initState() {
    super.initState();
    _loadReports();
    _loadReportDocuments();
  }

  Future<void> _loadReportDocuments() async {
    try {
      final response = await _documentService.getDocuments(
        fileType: 'pdf', // Focus on PDF reports
        search: 'report', // Search for report-related documents
      );
      
      if (response.isSuccess) {
        setState(() {
          _reportDocuments = (response.data!['documents'] as List).cast<RepositoryFile>();
        });
      }
    } catch (e) {
      // Handle error silently for now
      // Error loading report documents: $e
    }
  }

  Future<void> _loadReports() async {
    try {
      final response = await _reportService.getSignOffReports(
        status: _selectedFilter != 'all' ? _selectedFilter : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      debugPrint('📋 Load reports response: success=${response.isSuccess}, data type=${response.data?.runtimeType}');
      
      if (response.isSuccess && response.data != null) {
        // ApiClient already extracts the 'data' field, so response.data is the list directly
        // But check if it's a List or a Map with a 'data' key
        final reportsData = response.data is List 
            ? response.data as List
            : (response.data!['data'] as List? ?? []);
        
        debugPrint('📋 Parsed ${reportsData.length} reports');
        setState(() {
          _reports = reportsData.map((json) {
            // Map backend response to SignOffReport model
            final content = json['content'] as Map<String, dynamic>? ?? {};
            final reviews = json['reviews'] as List? ?? [];
            final latestReview = reviews.isNotEmpty ? reviews[0] : null;
            
            return SignOffReport(
              id: json['id']?.toString() ?? '',
              deliverableId: json['deliverableId']?.toString() ?? json['deliverable_id']?.toString() ?? '',
              reportTitle: content['reportTitle']?.toString() ?? 'Untitled Report',
              reportContent: content['reportContent']?.toString() ?? '',
              sprintIds: (content['sprintIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
              sprintPerformanceData: content['sprintPerformanceData']?.toString(),
              knownLimitations: content['knownLimitations']?.toString(),
              nextSteps: content['nextSteps']?.toString(),
              status: _parseStatus(json['status']?.toString() ?? 'draft'),
              createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
              createdBy: json['createdByName']?.toString() ?? json['created_by_name']?.toString() ?? 'Unknown',
              submittedAt: null, // Will be populated from audit logs if needed
              submittedBy: null,
              reviewedAt: latestReview != null && latestReview['approved_at'] != null
                  ? _parseDateTime(latestReview['approved_at'])
                  : null,
              reviewedBy: latestReview?['reviewerName']?.toString(),
              approvedAt: latestReview != null && latestReview['approved_at'] != null && latestReview['reviewStatus'] == 'approved'
                  ? _parseDateTime(latestReview['approved_at'])
                  : null,
              approvedBy: latestReview != null && latestReview['reviewStatus'] == 'approved'
                  ? latestReview['reviewerName']?.toString()
                  : null,
              changeRequestDetails: latestReview != null && latestReview['reviewStatus'] == 'change_requested'
                  ? latestReview['feedback']?.toString()
                  : null,
            );
          }).toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load reports: ${response.error ?? "Unknown error"}'),
              backgroundColor: FlownetColors.crimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    }
  }

  DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue).toLocal();
      } else if (dateValue is DateTime) {
        return dateValue.toLocal();
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateValue - $e');
    }
    return null;
  }

  ReportStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'under_review':
      case 'underreview':
        return ReportStatus.underReview;
      case 'approved':
        return ReportStatus.approved;
      case 'change_requested':
      case 'changerequested':
        return ReportStatus.changeRequested;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.draft;
    }
  }

  List<SignOffReport> get _filteredReports {
    var filtered = _reports;

    // Apply status filter
    if (_selectedFilter != 'all') {
      final status = ReportStatus.values.firstWhere(
        (e) => e.name == _selectedFilter,
        orElse: () => ReportStatus.draft,
      );
      filtered = filtered.where((report) => report.status == status).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((report) =>
          report.reportTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.createdBy.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.deliverableId.toLowerCase().contains(_searchQuery.toLowerCase()),
      ).toList();
    }

    return filtered;
  }

  void _showReportDetails(SignOffReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: Text(report.reportTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Status', report.statusDisplayName, report.statusColor),
                _buildDetailRow('Created By', report.createdBy),
                _buildDetailRow('Created At', _formatDate(report.createdAt)),
                if (report.submittedAt != null)
                  _buildDetailRow('Submitted At', _formatDate(report.submittedAt!)),
                if (report.reviewedAt != null)
                  _buildDetailRow('Reviewed At', _formatDate(report.reviewedAt!)),
                if (report.approvedAt != null)
                  _buildDetailRow('Approved At', _formatDate(report.approvedAt!)),
                if (report.clientComment != null) ...[
                  const SizedBox(height: 8),
                  const Text('Client Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(report.clientComment!),
                ],
                if (report.changeRequestDetails != null) ...[
                  const SizedBox(height: 8),
                  const Text('Change Request:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(report.changeRequestDetails!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAuditHistory(report.id);
            },
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Audit History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
              foregroundColor: FlownetColors.pureWhite,
            ),
          ),
          // Allow editing for draft and change_requested reports
          if (report.status == ReportStatus.draft || report.status == ReportStatus.changeRequested)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportEditorScreen(reportId: report.id),
                  ),
                ).then((_) => _loadReports());
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
              ),
            ),
          // Show review workflow for submitted reports
          if (report.status == ReportStatus.submitted || report.status == ReportStatus.underReview)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientReviewWorkflowScreen(reportId: report.id),
                  ),
                ).then((_) => _loadReports());
              },
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlownetColors.amberOrange,
                foregroundColor: FlownetColors.pureWhite,
              ),
            ),
          // Allow client feedback on any submitted/reviewed report
          if (report.status == ReportStatus.submitted || 
              report.status == ReportStatus.underReview ||
              report.status == ReportStatus.approved)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showClientFeedbackDialog(report);
              },
              icon: const Icon(Icons.comment, size: 18),
              label: const Text('Add Feedback'),
              style: TextButton.styleFrom(
                foregroundColor: FlownetColors.electricBlue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: FlownetColors.pureWhite),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? FlownetColors.coolGray),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuditHistory(String reportId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: FlownetColors.graphiteGray,
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Audit History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: FlownetColors.pureWhite,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: FlownetColors.pureWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: FlownetColors.slate),
              Expanded(
                child: AuditHistoryWidget(
                  reportId: reportId,
                  reportService: _reportService,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientFeedbackDialog(SignOffReport report) {
    final feedbackController = TextEditingController();
    bool requestChanges = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Row(
            children: [
              Icon(Icons.comment, color: FlownetColors.electricBlue),
              SizedBox(width: 8),
              Text(
                'Add Client Feedback',
                style: TextStyle(color: FlownetColors.pureWhite),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report: ${report.reportTitle}',
                  style: const TextStyle(
                    color: FlownetColors.coolGray,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text(
                    'Request changes to this report',
                    style: TextStyle(color: FlownetColors.pureWhite),
                  ),
                  value: requestChanges,
                  onChanged: (value) {
                    setState(() => requestChanges = value ?? false);
                  },
                  activeColor: FlownetColors.electricBlue,
                  checkColor: FlownetColors.pureWhite,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 8,
                  style: const TextStyle(color: FlownetColors.pureWhite),
                  decoration: InputDecoration(
                    labelText: requestChanges ? 'Change Request Details *' : 'Feedback/Comments',
                    labelStyle: const TextStyle(color: FlownetColors.coolGray),
                    hintText: requestChanges 
                        ? 'Describe what changes are needed...'
                        : 'Share your feedback or suggestions...',
                    hintStyle: const TextStyle(color: FlownetColors.coolGray),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: FlownetColors.slate),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: FlownetColors.slate),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: FlownetColors.electricBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: FlownetColors.coolGray)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (feedbackController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your feedback'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _submitClientFeedback(
                  report.id,
                  feedbackController.text.trim(),
                  requestChanges,
                );
              },
              icon: Icon(requestChanges ? Icons.change_circle : Icons.send),
              label: Text(requestChanges ? 'Request Changes' : 'Submit Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: requestChanges 
                    ? FlownetColors.amberOrange 
                    : FlownetColors.electricBlue,
                foregroundColor: FlownetColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitClientFeedback(String reportId, String feedback, bool requestChanges) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Submitting feedback...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final response = requestChanges
          ? await _reportService.requestChanges(reportId, feedback)
          : await _reportService.approveReport(reportId, comment: feedback);

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    requestChanges 
                        ? 'Changes requested successfully!' 
                        : 'Feedback submitted successfully!',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadReports(); // Reload to show updated status
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadReportDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        
        if (kIsWeb) {
          _showWebUploadDialog(pickedFile);
        } else {
          // Handle mobile/desktop upload
          _showUploadDialog(pickedFile);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: $e');
    }
  }

  void _showWebUploadDialog(PlatformFile pickedFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Upload Report Document', 
                         style: TextStyle(color: FlownetColors.pureWhite),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('File: ${pickedFile.name}',
                 style: const TextStyle(color: FlownetColors.coolGray),),
            const SizedBox(height: 16),
            const TextField(
              style: TextStyle(color: FlownetColors.pureWhite),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: FlownetColors.coolGray),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.coolGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.crimsonRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.coolGray)),
          ),
          ElevatedButton(
            onPressed: () => _performWebUpload(pickedFile),
            style: ElevatedButton.styleFrom(backgroundColor: FlownetColors.crimsonRed),
            child: const Text('Upload', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(PlatformFile pickedFile) {
    // Similar implementation for mobile/desktop
    _performWebUpload(pickedFile);
  }

  Future<void> _performWebUpload(PlatformFile pickedFile) async {
    Navigator.pop(context);
    
    if (pickedFile.bytes == null) {
      _showErrorSnackBar('Failed to read file. Please try again.');
      return;
    }
    
    try {
      final response = await _documentService.uploadWebDocument(
        fileBytes: pickedFile.bytes!,
        fileName: pickedFile.name,
        description: 'Report document: ${pickedFile.name}',
        tags: 'report, document',
      );
      
      if (response.isSuccess) {
        _showSuccessSnackBar('Report document uploaded successfully!');
        _loadReportDocuments();
      } else {
        _showErrorSnackBar('Upload failed: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Upload error: $e');
    }
  }

  Future<void> _previewDocument(RepositoryFile document) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: DocumentPreviewWidget(
          document: document,
          documentService: _documentService,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlownetColors.emeraldGreen,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlownetColors.crimsonRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FlownetColors.charcoalBlack,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
      ),
      floatingActionButton: RoleBuilder(
        allowedRoles: const ['deliveryLead', 'systemAdmin'],
        builder: (context) => FloatingActionButton.extended(
          onPressed: _showCreateReportDialog,
          icon: const Icon(Icons.add),
          label: const Text('New Sign-Off'),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('draft', 'Draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('submitted', 'Submitted'),
                      const SizedBox(width: 8),
                      _buildFilterChip('underReview', 'Under Review'),
                      const SizedBox(width: 8),
                      _buildFilterChip('approved', 'Approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('changeRequested', 'Change Requested'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reports and Documents Tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: FlownetColors.electricBlue,
                    unselectedLabelColor: FlownetColors.coolGray,
                    indicatorColor: FlownetColors.electricBlue,
                    tabs: [
                      Tab(text: 'Reports', icon: Icon(Icons.assignment)),
                      Tab(text: 'Documents', icon: Icon(Icons.folder)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Reports Tab
                        _filteredReports.isEmpty
                            ? const Center(
                                child: Text(
                                  'No reports found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredReports.length,
                                itemBuilder: (context, index) {
                                  final report = _filteredReports[index];
                                  return _buildReportCard(report);
                                },
                              ),
                        // Documents Tab
                        _reportDocuments.isEmpty
                            ? const Center(
                                child: Text(
                                  'No report documents found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _reportDocuments.length,
                                itemBuilder: (context, index) {
                                  final document = _reportDocuments[index];
                                  return _buildDocumentCard(document);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'createReportFAB',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportEditorScreen(),
                ),
              ).then((_) => _loadReports());
            },
            backgroundColor: FlownetColors.electricBlue,
            tooltip: 'Create Report',
            child: const Icon(Icons.add, color: FlownetColors.pureWhite),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'uploadDocumentFAB',
            onPressed: _uploadReportDocument,
            backgroundColor: FlownetColors.crimsonRed,
            tooltip: 'Upload Document',
            child: const Icon(Icons.upload, color: FlownetColors.pureWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(RepositoryFile document) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: FlownetColors.graphiteGray,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFileTypeColor(document.fileType),
          child: Text(
            document.fileType.toUpperCase().substring(0, 1),
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          document.name,
          style: const TextStyle(
            color: FlownetColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded by: ${document.uploaderName ?? document.uploader}',
              style: const TextStyle(color: FlownetColors.coolGray),
            ),
            Text(
              'Size: ${_formatFileSize(document.sizeInMB.toString())} • ${_formatDate(document.uploadDate)}',
              style: const TextStyle(color: FlownetColors.coolGray),
            ),
            if (document.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  document.description,
                  style: const TextStyle(
                    color: FlownetColors.coolGray,
                    fontSize: 12,
                  ),
                ),
              ),
            if (document.tags != null && document.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: document.tags!.split(',').map((tag) => Chip(
                    label: Text(tag.trim(), style: const TextStyle(fontSize: 10)),
                    backgroundColor: FlownetColors.electricBlue.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: FlownetColors.electricBlue),
                  ),).toList(),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: FlownetColors.electricBlue),
              onPressed: () => _previewDocument(document),
              tooltip: 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.download, color: FlownetColors.electricBlue),
              onPressed: () => _downloadDocument(document),
              tooltip: 'Download',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return FlownetColors.crimsonRed;
      case 'doc':
      case 'docx':
        return FlownetColors.amberOrange;
      case 'xls':
      case 'xlsx':
        return FlownetColors.emeraldGreen;
      case 'txt':
        return FlownetColors.slate;
      default:
        return FlownetColors.electricBlue;
    }
  }

  String _formatFileSize(String sizeInMB) {
    final size = double.tryParse(sizeInMB) ?? 0;
    if (size < 1) {
      return '${(size * 1024).toStringAsFixed(0)} KB';
    }
    return '${size.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _downloadDocument(RepositoryFile document) async {
    try {
      final response = await _documentService.downloadDocument(document.id);
      if (response.isSuccess) {
        _showSuccessSnackBar('Document downloaded successfully!');
      } else {
        _showErrorSnackBar('Download failed: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Download error: $e');
    }
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: FlownetColors.slate,
      selectedColor: FlownetColors.electricBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }

  Widget _buildReportCard(SignOffReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: FlownetColors.graphiteGray,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.reportTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: report.statusColor),
                    ),
                    child: Text(
                      report.statusDisplayName,
                      style: TextStyle(
                        color: report.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _confirmDeleteReport(report);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      report.createdBy,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      _formatDate(report.createdAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sprint IDs
              if (report.sprintIds.isNotEmpty)
                _buildInfoItem(
                  Icons.timeline,
                  'Sprints: ${report.sprintIds.join(', ')}',
                ),

              // Digital Signature indicator
              if (report.digitalSignature != null) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Digitally Signed',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Quick Action Buttons
              const SizedBox(height: 12),
              const Divider(color: FlownetColors.slate, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button for draft and change_requested reports
                  if (report.status == ReportStatus.draft || 
                      report.status == ReportStatus.changeRequested) ...[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportEditorScreen(reportId: report.id),
                          ),
                        ).then((_) => _loadReports());
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: FlownetColors.electricBlue,
                      ),
                    ),
                  ],
                  // Review button for submitted reports
                  if (report.status == ReportStatus.submitted || 
                      report.status == ReportStatus.underReview) ...[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientReviewWorkflowScreen(reportId: report.id),
                          ),
                        ).then((_) => _loadReports());
                      },
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: FlownetColors.amberOrange,
                      ),
                    ),
                  ],
                  // Feedback button for submitted/reviewed/approved reports
                  if (report.status == ReportStatus.submitted || 
                      report.status == ReportStatus.underReview ||
                      report.status == ReportStatus.approved) ...[
                    TextButton.icon(
                      onPressed: () => _showClientFeedbackDialog(report),
                      icon: const Icon(Icons.comment, size: 16),
                      label: const Text('Feedback'),
                      style: TextButton.styleFrom(
                        foregroundColor: FlownetColors.electricBlue,
                      ),
                    ),
                  ],
                  // Export button (for client reviewers and delivery leads)
                  if (AuthService().currentUser?.role == UserRole.clientReviewer || 
                      AuthService().currentUser?.role == UserRole.deliveryLead) ...[
                    TextButton.icon(
                      onPressed: () => _exportReport(report),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export'),
                      style: TextButton.styleFrom(
                        foregroundColor: FlownetColors.electricBlue,
                      ),
                    ),
                  ],
                  // View details button (always available)
                  TextButton.icon(
                    onPressed: () => _showReportDetails(report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: FlownetColors.coolGray,
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

  Future<void> _exportReport(SignOffReport report) async {
    try {
      // Show export options
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text(
            'Export Report',
            style: TextStyle(color: FlownetColors.pureWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: FlownetColors.electricBlue),
                title: const Text('PDF', style: TextStyle(color: FlownetColors.pureWhite)),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.print, color: FlownetColors.electricBlue),
                title: const Text('Print', style: TextStyle(color: FlownetColors.pureWhite)),
                onTap: () => Navigator.pop(context, 'print'),
              ),
            ],
          ),
        ),
      );

      if (format == null) return;

      if (format == 'pdf') {
        await _exportService.exportReportAsPDF(report);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (format == 'print') {
        await _exportService.printReport(report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
