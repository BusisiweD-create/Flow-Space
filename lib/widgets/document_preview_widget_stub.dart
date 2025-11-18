import 'package:flutter/material.dart';

// Temporary stub for web / deadline
// Accepts any parameters so screens won't crash
class DocumentPreviewWidget extends StatelessWidget {
  final dynamic document;
  final dynamic documentService; // added to avoid parameter errors

  const DocumentPreviewWidget({Key? key, this.document, this.documentService}) : super(key: key);

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
