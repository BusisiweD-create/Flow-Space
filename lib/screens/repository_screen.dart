import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repository_file.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final List<RepositoryFile> _files = [
    RepositoryFile(
      id: '1',
      name: 'project_design.pdf',
      uploader: 'Alice Johnson',
      size: 2.3,
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Project design document',
      fileType: 'pdf',
    ),
    RepositoryFile(
      id: '2',
      name: 'api_specs.json',
      uploader: 'Bob Smith',
      size: 0.156,
      uploadDate: DateTime.now().subtract(const Duration(days: 1)),
      description: 'API specifications',
      fileType: 'json',
    ),
    RepositoryFile(
      id: '3',
      name: 'database_schema.sql',
      uploader: 'Carol Davis',
      size: 0.089,
      uploadDate: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'Database schema file',
      fileType: 'sql',
    ),
  ];

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
            icon: const Icon(Icons.folder),
            onPressed: () {},
            tooltip: 'Repository',
          ),
        ],
      ),
      body: Column(
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
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getFileTypeColor(file.fileType),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Uploaded by: ${file.uploader}'),
                        Text('Size: ${_formatFileSize(file.size)}'),
                        Text('${_formatDate(file.uploadDate)}'),
                        if (file.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              file.description,
                              style: TextStyle(
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
                              color: FlownetColors.electricBlue),
                          onPressed: () => _downloadFile(file.id),
                          tooltip: 'Download',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: FlownetColors.crimsonRed),
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

  void _deleteFile(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _files.removeWhere((file) => file.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File deleted'),
                  backgroundColor: FlownetColors.crimsonRed,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _uploadFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload functionality would be implemented here'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }
}
