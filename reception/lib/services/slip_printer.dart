import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/slip.dart';
import '../utils/formatters.dart';

/// Builds and prints an appointment slip as a compact PDF.
///
/// The slip is generated locally from a [Slip] payload (fetched from the API or
/// reconstructed from an archived row), so reprints work offline. Layout is a
/// narrow A6-ish receipt suited to a desk/thermal printer.
class SlipPrinter {
  SlipPrinter._();

  static const _green = PdfColor.fromInt(0xFF2E7D5B);
  static const _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const _muted = PdfColor.fromInt(0xFF5B6B63);

  /// Build the PDF bytes for a slip. [hospitalName] overrides the slip's own
  /// (e.g. the configured station hospital name).
  static Future<Uint8List> buildPdf(Slip slip, {String? hospitalName}) async {
    final doc = pw.Document();
    final hospital =
        (hospitalName ?? slip.hospitalName).trim().isEmpty
            ? 'Aarvy Hospital'
            : (hospitalName ?? slip.hospitalName);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header band
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _green, width: 2),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      hospital,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: _green,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('Appointment Slip',
                        style: pw.TextStyle(fontSize: 10, color: _muted)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Token — the big number the patient waits on
              if (slip.tokenNumber != null)
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFE8F5E9),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('TOKEN',
                          style: pw.TextStyle(fontSize: 9, color: _muted)),
                      pw.Text('${slip.tokenNumber}',
                          style: pw.TextStyle(
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold,
                              color: _green)),
                    ],
                  ),
                ),

              _row('Patient', slip.patientName ?? '—'),
              if (slip.patientPhone != null && slip.patientPhone!.isNotEmpty)
                _row('Phone', slip.patientPhone!),
              _row('Doctor', slip.doctorName),
              _row('Specialty', slip.specialtyName),
              _row('Date', Fmt.longDate(slip.dateTime)),
              _row('Time', slip.slotLabel.isEmpty
                  ? Fmt.time(slip.dateTime)
                  : slip.slotLabel),
              _row('Fee', Fmt.rupees(slip.fee)),
              if (slip.statusLabel.isNotEmpty) _row('Status', slip.statusLabel),

              pw.Spacer(),
              pw.Divider(color: const PdfColor.fromInt(0xFFEAEFEC)),
              pw.Text(
                'Please arrive 10 minutes early and carry this slip.',
                style: pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
              pw.SizedBox(height: 2),
              pw.Text('Ref: ${slip.appointmentId}',
                  style: pw.TextStyle(
                      fontSize: 7.5,
                      color: const PdfColor.fromInt(0xFF93A199))),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 64,
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 9.5, color: _muted)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 10.5,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );

  /// Show the OS print dialog for a slip.
  static Future<void> print(Slip slip, {String? hospitalName}) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPdf(slip, hospitalName: hospitalName),
      name: 'Aarvy-slip-${slip.appointmentId}',
    );
  }

  /// Share/save the slip PDF (e.g. to email or a PDF file).
  static Future<void> share(Slip slip, {String? hospitalName}) async {
    final bytes = await buildPdf(slip, hospitalName: hospitalName);
    await Printing.sharePdf(
        bytes: bytes, filename: 'Aarvy-slip-${slip.appointmentId}.pdf');
  }
}
