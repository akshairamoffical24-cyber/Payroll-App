import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> generateAndDownloadReport({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? metadata,
  }) async {
    return exportAttendanceReportPdf(
      title: title,
      subtitle: subtitle,
      headers: headers,
      rows: rows,
      metadata: metadata,
    );
  }

  static Future<void> exportAttendanceReportPdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? metadata,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'WorkPulse HR / UBIHRM',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      subtitle,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Status: Official Audit Record',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                    ),
                  ],
                ),
              ],
            ),
            if (metadata != null && metadata.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: metadata.entries
                      .map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 20),
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: '${e.key}: ',
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.TextSpan(
                                  text: e.value,
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'WorkPulse Enterprise HRMS • Confidential Document',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 22,
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey50,
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Prepared By: System Automated Payroll & HR Engine', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Audit Hash: WP-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 140,
                    decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.8))),
                    child: pw.Center(
                      child: pw.Text('Authorized HR Signature', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }
}
