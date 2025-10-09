// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously, deprecated_member_use, avoid_print, prefer_const_constructors, unnecessary_brace_in_string_interps, require_trailing_commas, sort_child_properties_last, empty_statements, dead_code, use_key_in_widget_constructors, non_constant_identifier_names, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SignoffReportBuilderScreen extends ConsumerStatefulWidget {
  const SignoffReportBuilderScreen({super.key});

  @override
  ConsumerState<SignoffReportBuilderScreen> createState() => _SignoffReportBuilderScreenState();
}

class _SignoffReportBuilderScreenState extends ConsumerState<SignoffReportBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedEntityType = 'sprint';
  String _entityId = '';
  String _selectedFormat = 'html';
  bool _includeAuditLogs = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedReport;
  String? _errorMessage;

  final List<String> _entityTypes = ['sprint', 'deliverable'];
  final List<String> _formats = ['html', 'pdf', 'json', 'text'];
  
  get style => null;

  Future<void> _generateReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGenerating = true;
        _generatedReport = null;
        _errorMessage = null;
      });

      try {
        final url = Uri.parse('http://localhost:8000/api/v1/signoff/$_selectedEntityType/$_entityId/report?format=$_selectedFormat&include_audit_logs=$_includeAuditLogs');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final reportData = json.decode(response.body);
          setState(() {
            _generatedReport = reportData;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to generate report: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error generating report: $e';
        });
      } finally {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _downloadReport() async {
    if (_generatedReport != null) {
      try {
        final content = _getReportContent();
        final filename = _getReportFilename();
        
        // Save file to temporary directory
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);
        
        // Show download success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded: $filename'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openFile(file),
            ),
          ),
        );
        
        // Also share the file
        await _shareReport(file);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report generated yet')),
      );
    }
  }

  Future<void> _shareReport(File file) async {
    try {
      final shareResult = await Share.shareXFiles([XFile(file.path)],
        text: 'Sign-off Report - ${StringExtension(_selectedEntityType).capitalize()} $_entityId',
        subject: 'Flow Sign-off Report',
      );
      
      if (shareResult.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report shared successfully')),
        );
      }
    } catch (e) {
      // Sharing failed, but this is not critical
      print('Sharing failed: $e');
    }
  }

  Future<void> _openFile(File file) async {
    try {
      // For web, this would open in a new tab
      // For mobile/desktop, this would use platform-specific file opening
      if (_selectedFormat == 'html') {
        // Open HTML in browser
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTML report ready for viewing')),
        );
      } else {
        // Show file content in dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Report Content'),
            content: SingleChildScrollView(
              child: Text(file.readAsStringSync()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file: $e')),
      );
    }
  }

  void _previewReport() {
    if (_generatedReport != null && _selectedFormat == 'html') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPreviewScreen(
            htmlContent: _generatedReport!['content'],
            reportName: '${StringExtension(_selectedEntityType).capitalize()} $_entityId Report',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview only available for HTML reports')),
      );
    }
  }

  String _getReportContent() {
    if (_selectedFormat == 'json') {
      return JsonEncoder.withIndent('  ').convert(_generatedReport);
    } else {
      return _generatedReport!['content'] ?? '';
    }
  }

  String _getReportFilename() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'signoff_report_${_selectedEntityType}_${_entityId}_$timestamp.${_selectedFormat}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign-off Report Builder'),
        actions: [
          if (_generatedReport != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadReport,
              tooltip: 'Download Report',
            ),
          if (_generatedReport != null && _selectedFormat == 'html')
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _previewReport,
              tooltip: 'Preview Report',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Configuration Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Entity Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedEntityType,
                        decoration: const InputDecoration(
                          labelText: 'Entity Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _entityTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(StringExtension(type).capitalize()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEntityType = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Entity ID Input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Entity ID',
                          border: OutlineInputBorder(),
                          hintText: 'Enter entity ID',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an entity ID';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _entityId = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Format Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedFormat,
                        decoration: const InputDecoration(
                          labelText: 'Report Format',
                          border: OutlineInputBorder(),
                        ),
                        items: _formats.map((format) {
                          return DropdownMenuItem<String>(
                            value: format,
                            child: Text(format.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFormat = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Include Audit Logs Checkbox
                      CheckboxListTile(
                        title: const Text('Include Audit Logs'),
                        value: _includeAuditLogs,
                        onChanged: (value) {
                          setState(() {
                            _includeAuditLogs = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Generate Button
                      ElevatedButton(
                        onPressed: _isGenerating ? null : _generateReport,
                        child: _isGenerating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 8),
                                  Text('Generating...'),
                                ],
                              )
                            : const Text('Generate Report'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Generated Report Preview
            if (_generatedReport != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Generated Report',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Format: ${_selectedFormat.toUpperCase()}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_selectedFormat == 'json')
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                JsonEncoder.withIndent('  ').convert(_generatedReport),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          )
                        else if (_selectedFormat == 'text')
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _generatedReport!['content'] ?? '',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          )
                        else
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Preview not available for this format. Use download button to get the report.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Report Preview Screen for HTML content
class ReportPreviewScreen extends StatelessWidget {
  final String htmlContent;
  final String reportName;

  const ReportPreviewScreen({
    super.key,
    required this.htmlContent,
    required this.reportName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(reportName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: HtmlContentView(htmlContent: htmlContent),
      ),
    );
  }
}

// Simple HTML content viewer (would typically use a webview package)
class HtmlContentView extends StatelessWidget {
  final String htmlContent;

  const HtmlContentView({super.key, required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SelectableText(
        htmlContent,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
