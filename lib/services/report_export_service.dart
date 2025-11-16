import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/sign_off_report.dart';

class ReportExportService {
  /// Export report as PDF
  Future<void> exportReportAsPDF(SignOffReport report, {String? filePath}) async {
    try {
      final pdf = pw.Document();
      
      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SIGN-OFF REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatDate(report.createdAt),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Report Title
              pw.Text(
                report.reportTitle,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Report Content
              pw.Text(
                'Report Content',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                report.reportContent,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 15),
              
              // Known Limitations
              if (report.knownLimitations != null && report.knownLimitations!.isNotEmpty) ...[
                pw.Text(
                  'Known Limitations',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  report.knownLimitations!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 15),
              ],
              
              // Next Steps
              if (report.nextSteps != null && report.nextSteps!.isNotEmpty) ...[
                pw.Text(
                  'Next Steps',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  report.nextSteps!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 15),
              ],
              
              // Status and Metadata
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Status: ${_formatStatus(report.status)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Created by: ${report.createdBy}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (report.approvedAt != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Approved on: ${_formatDate(report.approvedAt!)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        if (report.approvedBy != null)
                          pw.Text(
                            'Approved by: ${report.approvedBy}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                ],
              ),
            ];
          },
        ),
      );
      
      // Save or share PDF
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        final base64Pdf = base64Encode(bytes);
        await Share.share(
          'data:application/pdf;base64,$base64Pdf',
          subject: 'Sign-Off Report: ${report.reportTitle}',
        );
      } else {
        final xFile = XFile.fromData(
          bytes,
          name: 'report_${report.id}.pdf',
          mimeType: 'application/pdf',
        );
        if (filePath != null && filePath.isNotEmpty) {
          try {
            await xFile.saveTo(filePath);
          } catch (_) {}
        }
        await Share.shareXFiles(
          [xFile],
          text: 'Sign-Off Report: ${report.reportTitle}',
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      rethrow;
    }
  }
  
  /// Print report
  Future<void> printReport(SignOffReport report) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Text(
                report.reportTitle,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                report.reportContent,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ];
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error printing report: $e');
      rethrow;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'Draft';
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.changeRequested:
        return 'Change Requested';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }
}

