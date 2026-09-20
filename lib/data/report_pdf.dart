import 'dart:typed_data';

import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a printable PPE compliance report.
Future<Uint8List> buildReportPdf({
  required String siteName,
  required String supervisor,
  required List<ScanRecord> scans,
  required Employee? Function(String id) employeeOf,
  DateTime? generatedAt,
}) async {
  final doc = pw.Document(title: 'GearGuard PPE report', author: supervisor);
  final now = generatedAt ?? DateTime.now();
  final compliant = scans.where((s) => s.compliant).length;
  final rate = scans.isEmpty ? 0.0 : compliant / scans.length;

  const orange = PdfColor.fromInt(0xFFFF6B00);
  const grey = PdfColor.fromInt(0xFF64748B);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: orange, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GearGuard',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: orange,
              ),
            ),
            pw.Text(
              'PPE Compliance Report',
              style: const pw.TextStyle(fontSize: 12, color: grey),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: grey),
        ),
      ),
      build: (context) => [
        pw.SizedBox(height: 16),
        pw.Text('Site: $siteName', style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          'Prepared by: $supervisor',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'Generated: ${formatStamp(now)}',
          style: const pw.TextStyle(fontSize: 12, color: grey),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            _kpi('Total scans', '${scans.length}'),
            _kpi('Compliant', '$compliant'),
            _kpi('Violations', '${scans.length - compliant}'),
            _kpi('Compliance rate', formatPercent(rate)),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: const pw.BoxDecoration(color: orange),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 5,
          ),
          headers: const [
            'Date & time',
            'Employee',
            'Department',
            'Result',
            'Missing',
          ],
          data: [
            for (final s in scans)
              [
                formatStamp(s.time),
                employeeOf(s.employeeId)?.name ?? 'Removed employee',
                employeeOf(s.employeeId)?.department ?? '-',
                if (s.compliant) 'Compliant' else 'Violation',
                if (s.missing.isEmpty)
                  '-'
                else
                  s.missing.map((m) => m.label).join(', '),
              ],
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _kpi(String label, String value) => pw.Expanded(
  child: pw.Container(
    margin: const pw.EdgeInsets.only(right: 8),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromInt(0xFF64748B),
          ),
        ),
      ],
    ),
  ),
);
