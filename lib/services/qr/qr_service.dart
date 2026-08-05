import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class QRService {
  static const String _tag = 'QRService';

  String buildWifiQrString({
    required String ssid,
    required String password,
    String security = 'WPA/WPA2', // 'WPA/WPA2', 'WPA3', 'WEP', 'Open'
    bool isHidden = false,
  }) {
    String secCode = 'WPA';
    if (security == 'WEP') {
      secCode = 'WEP';
    } else if (security == 'Open' || password.isEmpty) {
      secCode = 'nopass';
    } else if (security == 'WPA3') {
      secCode = 'SAE';
    }
    final hiddenFlag = isHidden ? 'true' : 'false';
    return 'WIFI:S:$ssid;T:$secCode;P:$password;H:$hiddenFlag;;';
  }

  String buildVCardString({
    required String name,
    String? phone,
    String? email,
    String? org,
    String? url,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$name;;;;');
    buffer.writeln('FN:$name');
    if (org != null && org.isNotEmpty) buffer.writeln('ORG:$org');
    if (phone != null && phone.isNotEmpty) buffer.writeln('TEL;TYPE=CELL:$phone');
    if (email != null && email.isNotEmpty) buffer.writeln('EMAIL:$email');
    if (url != null && url.isNotEmpty) buffer.writeln('URL:$url');
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  bool isUrlSafe(String content) {
    if (!content.startsWith('http://') && !content.startsWith('https://')) {
      return true;
    }
    final lower = content.toLowerCase();
    // Safety heuristic warning against suspicious executable or phishing scripts
    if (lower.contains('.apk') ||
        lower.contains('.exe') ||
        lower.contains('.sh') ||
        lower.contains('phish') ||
        lower.contains('malware')) {
      return false;
    }
    return true;
  }

  String detectQRType(String content) {
    final trim = content.trim();
    if (trim.startsWith('WIFI:')) {
      return 'wifi';
    } else if (trim.startsWith('http://') || trim.startsWith('https://') || trim.startsWith('www.')) {
      return 'url';
    } else if (trim.startsWith('mailto:') || RegExp(r'^\S+@\S+\.\S+$').hasMatch(trim)) {
      return 'email';
    } else if (RegExp(r'^(?:\d{8}|\d{12,14})$').hasMatch(trim)) {
      return 'barcode';
    } else if (trim.startsWith('tel:') || RegExp(r'^\+?\d{8,15}$').hasMatch(trim)) {
      return 'phone';
    } else if (trim.startsWith('smsto:') || trim.startsWith('sms:')) {
      return 'sms';
    } else if (trim.startsWith('BEGIN:VCARD')) {
      return 'contact';
    } else if (trim.startsWith('geo:') || trim.startsWith('http://maps.google.com')) {
      return 'location';
    } else if (trim.toLowerCase().contains('pay') || trim.startsWith('upi:')) {
      return 'payment';
    } else {
      return 'text';
    }
  }

  Future<File?> exportQrReportAsPdf({
    required String title,
    required String qrContent,
    String? subtitle,
  }) async {
    try {
      final doc = pw.Document(
        title: '$title - ScanX AI QR Report',
        creator: AppConstants.developerName,
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppConstants.appName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'QR & Wi-Fi Toolkit Verification Card',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.Divider(height: 24),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Title: $title',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ],
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'QR Payload Data:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        qrContent,
                        style: const pw.TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      AppConstants.developerName,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      AppConstants.copyrightText,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final outputFile = File('${outputDir.path}/qr_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final bytes = await doc.save();
      await outputFile.writeAsBytes(bytes);

      AppLogger.i('QR Report PDF generated at: ${outputFile.path}', _tag);
      return outputFile;
    } catch (e) {
      AppLogger.e('Failed to export QR Report PDF: $e', tag: _tag);
      return null;
    }
  }

  Future<void> printQrCard({
    required String title,
    required String qrContent,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) async {
          final doc = pw.Document();
          doc.addPage(
            pw.Page(
              build: (ctx) => pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text('Payload: $qrContent'),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'ScanX AI • ${AppConstants.developerName}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ),
          );
          return doc.save();
        },
        name: title,
      );
    } catch (e) {
      AppLogger.e('Print QR Card failed: $e', tag: _tag);
    }
  }
}
