import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repository_file.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<RepositoryFile> _files = [
    RepositoryFile(
      id: '1',
      name: 'project_design.pdf',
      fileType: 'PDF',
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      uploadedBy: 'Alice Johnson',
      size: '2.3 MB',
      description: 'Project design document',
    ),
    RepositoryFile(
      id: '2',
      name: 'api_specs.json',
      fileType: 'JSON',
      uploadDate: DateTime.now().subtract(const Duration(days: 1)),
      uploadedBy: 'Bob Smith',
      size: '156 KB',
      description: 'API specifications',
    ),
    RepositoryFile(
      id: '3',
      name: 'database_schema.sql',
      fileType: 'SQL',
      uploadDate: DateTime.now().subtract(const Duration(hours: 6)),
      uploadedBy: 'Carol Davis',
      size: '89 KB',
      description: 'Database schema file',
    ),
  ];

  List<RepositoryFile> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _filteredFiles = _files;
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFiles() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredFiles = _files;
      } else {
        _filteredFiles = _files.where((file) {
          return file.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              file.fileType
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
            tooltip: 'Upload File',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
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
            child: _filteredFiles.isEmpty
                ? const Center(
                    child: Text('No files found'),
                  )
                : ListView.builder(
                    itemCount: _filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = _filteredFiles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getFileTypeColor(file.fileType),
                            child: Text(
                              file.fileType.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
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
                              Text('Uploaded by: ${file.uploadedBy}'),
                              Text(
                                  'Size: ${file.size} • ${_formatDate(file.uploadDate)}'),
                              if (file.description.isNotEmpty)
                                Text(
                                  file.description,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => _downloadFile(file.id),
                                tooltip: 'Download',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteFile(file.id),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        tooltip: 'Upload File',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'JSON':
        return Colors.blue;
      case 'SQL':
        return Colors.green;
      case 'DOC':
      case 'DOCX':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _downloadFile(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started')),
    );
  }

  void _deleteFile(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _filterFiles();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: const Text('File upload functionality would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('File upload feature coming soon')),
              );
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
