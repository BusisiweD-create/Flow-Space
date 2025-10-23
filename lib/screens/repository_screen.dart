import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/repository_file.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class RepositoryScreen extends StatefulWidget {
  const RepositoryScreen({super.key});

  @override
  State<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends State<RepositoryScreen> {
  final DocumentService _documentService = DocumentService(AuthService());
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  List<RepositoryFile> _documents = [];
  List<RepositoryFile> _filteredDocuments = [];
  bool _isLoading = false;
  String _selectedFileType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _documentService.getDocuments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        fileType: _selectedFileType != 'all' ? _selectedFileType : null,
      );
      
      if (response.isSuccess) {
        setState(() {
          _documents = (response.data!['documents'] as List).cast<RepositoryFile>();
          _filteredDocuments = _documents;
        });
      } else {
        _showErrorSnackBar('Failed to load documents: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        
        // For web platform, we need to handle the file differently
        if (kIsWeb) {
          // On web, we can't create a File from path, so we'll handle it differently
          _showWebUploadDialog(pickedFile);
        } else {
          final file = File(pickedFile.path!);
          _showUploadDialog(file);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: $e');
    }
  }

  void _showUploadDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Upload Document', style: TextStyle(color: FlownetColors.pureWhite)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.path.split('/').last}', 
                   style: const TextStyle(color: FlownetColors.coolGray),),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: FlownetColors.coolGray),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: FlownetColors.pureWhite),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (optional, comma-separated)',
                  labelStyle: TextStyle(color: FlownetColors.coolGray),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: FlownetColors.pureWhite),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _descriptionController.clear();
              _tagsController.clear();
            },
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.coolGray)),
          ),
          ElevatedButton(
            onPressed: () => _performUpload(file),
            style: ElevatedButton.styleFrom(backgroundColor: FlownetColors.crimsonRed),
            child: const Text('Upload', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpload(File file) async {
    Navigator.pop(context);
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _documentService.uploadDocument(
        filePath: file.path,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        tags: _tagsController.text.isNotEmpty ? _tagsController.text : null,
      );
      
      if (response.isSuccess) {
        _showSuccessSnackBar('Document uploaded successfully!');
        _descriptionController.clear();
        _tagsController.clear();
        _loadDocuments();
      } else {
        _showErrorSnackBar('Failed to upload document: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showWebUploadDialog(PlatformFile pickedFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Upload Document', style: TextStyle(color: FlownetColors.pureWhite)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'File: ${pickedFile.name}',
                style: const TextStyle(color: FlownetColors.pureWhite),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: FlownetColors.pureWhite),
                decoration: const InputDecoration(
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
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                style: const TextStyle(color: FlownetColors.pureWhite),
                decoration: const InputDecoration(
                  labelText: 'Tags (optional, comma-separated)',
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

  Future<void> _performWebUpload(PlatformFile pickedFile) async {
    Navigator.pop(context);
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _documentService.uploadWebDocument(
        fileBytes: pickedFile.bytes!,
        fileName: pickedFile.name,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        tags: _tagsController.text.isNotEmpty ? _tagsController.text : null,
      );
      
      if (response.isSuccess) {
        _showSuccessSnackBar('Document uploaded successfully!');
        _descriptionController.clear();
        _tagsController.clear();
        _loadDocuments();
      } else {
        _showErrorSnackBar('Failed to upload document: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadDocument(RepositoryFile document) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _documentService.downloadDocument(document.id);
      
      if (response.isSuccess) {
        if (kIsWeb) {
          // For web, the download should trigger automatically
          _showSuccessSnackBar('Document download started!');
        } else {
          final filePath = response.data!['filePath'];
          _showSuccessSnackBar('Document downloaded to: $filePath');
          
          // Try to open the file
          final file = File(filePath);
          if (await file.exists()) {
            final uri = Uri.file(file.path);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        }
      } else {
        _showErrorSnackBar('Failed to download document: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error downloading document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDocument(RepositoryFile document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Delete Document', style: TextStyle(color: FlownetColors.pureWhite)),
        content: Text('Are you sure you want to delete "${document.name}"?', 
                     style: const TextStyle(color: FlownetColors.coolGray),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: FlownetColors.coolGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: FlownetColors.crimsonRed),
            child: const Text('Delete', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        final response = await _documentService.deleteDocument(document.id);
        
        if (response.isSuccess) {
          _showSuccessSnackBar('Document deleted successfully!');
          _loadDocuments();
        } else {
          _showErrorSnackBar('Failed to delete document: ${response.error}');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting document: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _previewDocument(RepositoryFile document) async {
    try {
      final response = await _documentService.getDocumentPreview(document.id);
      
      if (response.isSuccess) {
        final previewData = response.data!;
        _showPreviewDialog(document, previewData);
      } else {
        _showErrorSnackBar('Preview not available: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error getting preview: $e');
    }
  }

  void _showPreviewDialog(RepositoryFile document, Map<String, dynamic> previewData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: Text('Preview: ${document.name}', 
                   style: const TextStyle(color: FlownetColors.pureWhite),),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Type: ${document.fileType.toUpperCase()}', 
                   style: const TextStyle(color: FlownetColors.coolGray),),
              Text('Size: ${_formatFileSize(document.sizeInMB)}', 
                   style: const TextStyle(color: FlownetColors.coolGray),),
              if (document.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Description: ${document.description}', 
                             style: const TextStyle(color: FlownetColors.coolGray),),
                ),
              const SizedBox(height: 16),
              if (previewData['previewAvailable'] == true)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FlownetColors.charcoalBlack,
                      border: Border.all(color: FlownetColors.slate),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        'Document content preview would appear here.\n\nFor ${document.fileType.toUpperCase()} files, you can download and open them with the appropriate application.',
                        style: const TextStyle(color: FlownetColors.pureWhite),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FlownetColors.amberOrange.withValues(alpha: 0.1),
                    border: Border.all(color: FlownetColors.amberOrange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Preview not available for this file type.\nDownload the file to view its contents.',
                    style: TextStyle(color: FlownetColors.amberOrange),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: FlownetColors.coolGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadDocument(document);
            },
            style: ElevatedButton.styleFrom(backgroundColor: FlownetColors.electricBlue),
            child: const Text('Download', style: TextStyle(color: FlownetColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  void _filterDocuments() {
    setState(() {
      _filteredDocuments = _documents.where((doc) {
        final matchesSearch = _searchQuery.isEmpty || 
            doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doc.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesFileType = _selectedFileType == 'all' || 
            doc.fileType.toLowerCase() == _selectedFileType.toLowerCase();
        
        return matchesSearch && matchesFileType;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _filterDocuments();
  }

  void _onFileTypeChanged(String? value) {
    setState(() {
      _selectedFileType = value ?? 'all';
    });
    _filterDocuments();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: FlownetColors.graphiteGray,
              border: Border(
                bottom: BorderSide(color: FlownetColors.slate, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
            child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search documents...',
                      hintStyle: TextStyle(color: FlownetColors.coolGray),
                      prefixIcon: Icon(Icons.search, color: FlownetColors.coolGray),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: FlownetColors.charcoalBlack,
                    ),
                    style: const TextStyle(color: FlownetColors.pureWhite),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFileType,
                  onChanged: _onFileTypeChanged,
                  dropdownColor: FlownetColors.graphiteGray,
                  style: const TextStyle(color: FlownetColors.pureWhite),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'docx', child: Text('Word')),
                    DropdownMenuItem(value: 'xlsx', child: Text('Excel')),
                    DropdownMenuItem(value: 'txt', child: Text('Text')),
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                    DropdownMenuItem(value: 'sql', child: Text('SQL')),
                  ],
                ),
              ],
            ),
          ),
          
          // Documents list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.crimsonRed),
                    ),
                  )
                : _filteredDocuments.isEmpty
                    ? const Center(
                        child: Text(
                          'No documents found',
                          style: TextStyle(
                            color: FlownetColors.coolGray,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDocuments.length,
              itemBuilder: (context, index) {
                          final document = _filteredDocuments[index];
                          return _buildDocumentCard(document);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadDocument,
        backgroundColor: FlownetColors.crimsonRed,
        child: const Icon(Icons.add, color: FlownetColors.pureWhite),
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
              'Size: ${_formatFileSize(document.sizeInMB)} • ${_formatDate(document.uploadDate)}',
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
                        IconButton(
              icon: const Icon(Icons.delete, color: FlownetColors.crimsonRed),
              onPressed: () => _deleteDocument(document),
                          tooltip: 'Delete',
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
      case 'json':
        return FlownetColors.electricBlue;
      case 'sql':
        return FlownetColors.emeraldGreen;
      case 'doc':
      case 'docx':
        return FlownetColors.amberOrange;
      case 'xlsx':
      case 'xls':
        return FlownetColors.emeraldGreen;
      case 'txt':
        return FlownetColors.slate;
      default:
        return FlownetColors.slate;
    }
  }

  String _formatFileSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
