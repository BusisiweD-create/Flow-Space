import 'package:flutter/material.dart';
import '../models/repository_file.dart';
import '../services/document_service.dart';

// Temporary stub for web / deadline
// Accepts any parameters so screens won't crash
class DocumentPreviewWidget extends StatelessWidget {
  final RepositoryFile document;
  final DocumentService documentService;

  const DocumentPreviewWidget({
    super.key,
    required this.document,
    required this.documentService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Text(
          'Document preview disabled for web',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
