// ignore_for_file: unused_element, require_trailing_commas, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/repository_file.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../services/api_service.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  List<RepositoryFile> _files = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use actual API call to get project files
      // For demo purposes, we'll use a default project ID
      final filesData = await ApiService.getProjectFiles('default-project-id');
      
      // Convert API response to RepositoryFile objects
      final files = filesData.map((fileData) {
        return RepositoryFile(
          id: fileData['id']?.toString() ?? '',
          name: fileData['name']?.toString() ?? 'Unknown File',
          fileType: fileData['fileType']?.toString() ?? 'document',
          uploadDate: fileData['uploadDate'] != null 
              ? DateTime.parse(fileData['uploadDate'])
              : DateTime.now(),
          uploadedBy: fileData['uploadedBy']?.toString() ?? '',
          size: fileData['size']?.toString() ?? '0 MB',
          description: fileData['description']?.toString() ?? '',
          uploader: fileData['uploader']?.toString() ?? 'Unknown User',
          sizeInMB: (fileData['sizeInMB'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load files: \$e';
      });
    }
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
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: FlownetColors.electricBlue,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: FlownetColors.crimsonRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: FlownetColors.pureWhite,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlownetColors.electricBlue,
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: FlownetColors.pureWhite),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search files...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Files list
                    Expanded(
                      child: _files.isEmpty
                          ? const Center(
                              child: Text(
                                'No files found',
                                style: TextStyle(
                                  color: FlownetColors.pureWhite,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getFileTypeColor(file.fileType),
                                      child: Text(
                                        file.fileType.toUpperCase().substring(0, 1),
                                        style: const TextStyle(
                                          color: FlownetColors.pureWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      file.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Uploaded by: \${file.uploader}'),
                                        const Text('Size: \${_formatFileSize(file.sizeInMB)}'),
                                        Text(_formatDate(file.uploadDate)),
                                        if (file.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              file.description,
                                              style: const TextStyle(
                                                color: FlownetColors.coolGray,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.download,
                                              color: FlownetColors.electricBlue,),
                                          onPressed: () => _downloadFile(file.id),
                                          tooltip: 'Download',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: FlownetColors.crimsonRed,),
                                          onPressed: () => _deleteFile(file.id),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        backgroundColor: FlownetColors.crimsonRed,
        child: const Icon(Icons.add, color: FlownetColors.pureWhite),
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

  void _downloadFile(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download started'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }

  Future<void> _deleteFile(String id) async {
    try {
      // Use actual API call to delete file
      final success = await ApiService.deleteFile(id);
      
      if (success) {
        // Remove from local list if API call succeeded
        setState(() {
          _files.removeWhere((file) => file.id == id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: FlownetColors.emeraldGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete file'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting file: $e'),
          backgroundColor: FlownetColors.crimsonRed,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    // Handle web platform where file_picker may not work properly
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File upload is not supported in web browser. Please use the desktop app for file uploads.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Open file picker to select files
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'json', 'sql', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null && result.files.isNotEmpty) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: FlownetColors.graphiteGray,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: FlownetColors.electricBlue),
                SizedBox(height: 16),
                Text('Uploading files...', style: TextStyle(color: FlownetColors.pureWhite)),
              ],
            ),
          ),
        );

        // Upload each selected file
        int successfulUploads = 0;
        for (final file in result.files) {
          try {
            final uploadResult = await ApiService.uploadFile(
              projectId: 'default-project-id',
              fileName: file.name,
              fileType: file.extension ?? 'document',
              description: 'Uploaded via file picker',
              filePath: file.path ?? '',
              fileBytes: file.bytes,
            );

            if (uploadResult != null) {
              successfulUploads++;
            }
          } catch (e) {
            debugPrint('Failed to upload file \${file.name}: \$e');
          }
        }

        // Close loading dialog
        Navigator.of(context).pop();

        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successfulUploads > 0
                  ? 'Successfully uploaded \$successfulUploads file(s)'
                  : 'No files were uploaded',
            ),
            backgroundColor: successfulUploads > 0
                ? FlownetColors.emeraldGreen
                : FlownetColors.amberOrange,
          ),
        );

        // Reload files list if any upload was successful
        if (successfulUploads > 0) {
          _loadFiles();
        }
      } else {
        // User canceled file selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File selection canceled'),
            backgroundColor: FlownetColors.slate,
          ),
        );
      }
    } catch (e) {
      // Close any open dialogs
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting files: \$e'),
          backgroundColor: FlownetColors.crimsonRed,
        ),
      );
    }
  }
}