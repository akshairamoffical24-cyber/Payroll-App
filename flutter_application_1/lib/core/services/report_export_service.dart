import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportExportService {
  /// Converts tabular data into standard CSV bytes
  static Uint8List exportToCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final csvData = [headers, ...rows];
    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(csvString.codeUnits);
  }

  /// Converts tabular data into .xlsx Excel bytes
  static Uint8List exportToExcel({
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final excel = Excel.createExcel();
    final cleanSheetName = sheetName.replaceAll(RegExp(r'[\\/?*\[\]]'), '_').trim();
    final sheet = excel[cleanSheetName.isNotEmpty ? cleanSheetName : 'Report_Data'];
    excel.setDefaultSheet(sheet.sheetName);

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
    );

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    for (var r = 0; r < rows.length; r++) {
      final rowData = rows[r];
      for (var c = 0; c < rowData.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        final val = rowData[c];
        if (val is num) {
          cell.value = DoubleCellValue(val.toDouble());
        } else if (val is bool) {
          cell.value = BoolCellValue(val);
        } else {
          cell.value = TextCellValue(val?.toString() ?? '');
        }
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Prints or downloads PDF report
  static Future<void> printOrExportPdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WorkPulse Enterprise: $title',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        subtitle,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellHeight: 22,
              cellAlignments: {for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft},
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_Report.pdf',
    );
  }
}
