import 'package:flutter/material.dart';
import '../models/repository_file.dart';
import '../services/document_service.dart';
import '../theme/flownet_theme.dart';

/// Document preview widget - uses stub implementation for now
/// This is a simplified version that works across all platforms
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
      constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
      decoration: BoxDecoration(
        color: FlownetColors.graphiteGray,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: FlownetColors.charcoalBlack.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: FlownetColors.slate,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(),
                  color: FlownetColors.pureWhite,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: FlownetColors.pureWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${document.fileType.toUpperCase()} • ${_formatFileSize(document.sizeInMB)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FlownetColors.coolGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: FlownetColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getFileIcon(),
                    size: 64,
                    color: FlownetColors.coolGray,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Document Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FlownetColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preview for ${document.fileType.toUpperCase()} files is available.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: FlownetColors.coolGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _downloadDocument(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
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
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    switch (document.fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  Future<void> _downloadDocument(BuildContext context) async {
    try {
      final response = await documentService.downloadDocument(document.id);
      if (response.isSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document downloaded: ${response.data?['fileName'] ?? document.name}'),
              backgroundColor: FlownetColors.emeraldGreen,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${response.error}'),
              backgroundColor: FlownetColors.crimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    }
  }
}

