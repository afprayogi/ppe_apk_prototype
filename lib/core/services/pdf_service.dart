import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/detection_model.dart';
import '../../models/employee_model.dart';
import '../services/settings_service.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  static const _green  = PdfColor.fromInt(0xFF2E7D32);
  static const _green2 = PdfColor.fromInt(0xFF4CAF50);
  static const _red    = PdfColor.fromInt(0xFFC62828);
  static const _grey   = PdfColor.fromInt(0xFF757575);
  static const _bgGrey = PdfColor.fromInt(0xFFF5F5F5);

  /// Export laporan semua deteksi ke PDF dan tampilkan share/print dialog
  Future<void> exportLaporanDeteksi(List<DetectionRecord> records) async {
    final doc = pw.Document();
    final font  = await PdfGoogleFonts.openSansRegular();
    final fontB = await PdfGoogleFonts.openSansBold();
    final now   = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now());
    final company = SettingsService.instance.companyName;

    // Group per hari
    final grouped = <String, List<DetectionRecord>>{};
    for (final r in records) {
      final key = DateFormat('dd MMM yyyy').format(r.detectedAt);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN DETEKSI APD',
                        style: pw.TextStyle(font: fontB, fontSize: 18,
                            color: PdfColors.white)),
                    pw.Text(company,
                        style: pw.TextStyle(font: font, fontSize: 11,
                            color: PdfColors.grey300)),
                  ],
                ),
                pw.Text('Dicetak: $now',
                    style: pw.TextStyle(font: font, fontSize: 9,
                        color: PdfColors.grey300)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Ringkasan
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _bgGrey,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(font, fontB, 'Total Scan',
                    records.length.toString()),
                _summaryItem(font, fontB, 'Lengkap',
                    records.where((r) => r.isComplete).length.toString()),
                _summaryItem(font, fontB, 'Tidak Lengkap',
                    records.where((r) => !r.isComplete).length.toString()),
                _summaryItem(font, fontB, 'Karyawan Unik',
                    records.map((r) => r.employeeId).toSet().length.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Per-hari tabel
          ...grouped.entries.map((entry) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _green2,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(entry.key,
                    style: pw.TextStyle(font: fontB, fontSize: 11,
                        color: PdfColors.white)),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(0.8),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _bgGrey),
                    children: ['Nama', 'NIA', 'APD Terdeteksi',
                      'APD Kurang', 'Status']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      font: fontB, fontSize: 9)),
                            ))
                        .toList(),
                  ),
                  // Data rows
                  ...entry.value.map((r) => pw.TableRow(children: [
                    _cell(font, r.employeeName),
                    _cell(font, r.nia),
                    _cell(font, r.detectedPpe.isEmpty
                        ? '-' : r.detectedPpe.join(', ')),
                    _cell(font, r.missingPpe.isEmpty
                        ? '-' : r.missingPpe.join(', '),
                        color: r.missingPpe.isEmpty ? null : _red),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: r.isComplete ? _green2 : _red,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                            r.isComplete ? 'OK' : 'KURANG',
                            style: pw.TextStyle(font: fontB, fontSize: 7,
                                color: PdfColors.white)),
                      ),
                    ),
                  ])),
                ],
              ),
              pw.SizedBox(height: 14),
            ],
          )),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'laporan_apd_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Export history satu karyawan
  Future<void> exportEmployeeHistory(
      EmployeeModel emp, List<DetectionRecord> records) async {
    final doc  = pw.Document();
    final font  = await PdfGoogleFonts.openSansRegular();
    final fontB = await PdfGoogleFonts.openSansBold();
    final now  = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now());

    final compliant = records.where((r) => r.isComplete).length;
    final rate = records.isEmpty ? 0
        : (compliant / records.length * 100).toInt();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('REKAM JEJAK APD KARYAWAN',
                  style: pw.TextStyle(font: fontB, fontSize: 16,
                      color: PdfColors.white)),
              pw.SizedBox(height: 8),
              pw.Text('Nama : ${emp.name}',
                  style: pw.TextStyle(font: fontB, fontSize: 12,
                      color: PdfColors.white)),
              pw.Text('NIA  : ${emp.nia}  |  Shift: ${emp.shift}',
                  style: pw.TextStyle(font: font, fontSize: 10,
                      color: PdfColors.grey300)),
              pw.Text('Dicetak: $now',
                  style: pw.TextStyle(font: font, fontSize: 9,
                      color: PdfColors.grey300)),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              color: _bgGrey,
              borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(font, fontB, 'Total Scan',
                  records.length.toString()),
              _summaryItem(font, fontB, 'Lengkap',
                  compliant.toString()),
              _summaryItem(font, fontB, 'Tidak Lengkap',
                  (records.length - compliant).toString()),
              _summaryItem(font, fontB, 'Kepatuhan',
                  '$rate%'),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(
              color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _bgGrey),
              children: ['Tanggal', 'APD Ada', 'APD Kurang',
                'Status', 'Conf%']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h,
                            style: pw.TextStyle(font: fontB, fontSize: 9)),
                      ))
                  .toList(),
            ),
            ...records.map((r) => pw.TableRow(children: [
              _cell(font,
                  DateFormat('dd/MM HH:mm').format(r.detectedAt)),
              _cell(font,
                  r.detectedPpe.isEmpty ? '-' : r.detectedPpe.join(', ')),
              _cell(font,
                  r.missingPpe.isEmpty ? '-' : r.missingPpe.join(', '),
                  color: r.missingPpe.isEmpty ? null : _red),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: r.isComplete ? _green2 : _red,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(r.isComplete ? 'OK' : 'NO',
                      style: pw.TextStyle(font: fontB, fontSize: 7,
                          color: PdfColors.white)),
                ),
              ),
              _cell(font,
                  '${r.overallConfidence.toStringAsFixed(0)}%'),
            ])),
          ],
        ),
      ],
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'apd_${emp.nia}_'
          '${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _summaryItem(
      pw.Font font, pw.Font fontB, String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(font: fontB, fontSize: 18, color: _green)),
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 8, color: _grey)),
      ],
    );
  }

  pw.Widget _cell(pw.Font font, String text,
      {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font, fontSize: 8, color: color ?? PdfColors.black)),
    );
  }
}
