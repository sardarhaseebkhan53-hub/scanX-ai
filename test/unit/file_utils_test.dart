import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/core/utils/file_utils.dart';

void main() {
  group('FileUtils Unit Tests', () {
    test('formatFileSize converts bytes to readable string correctly', () {
      expect(FileUtils.formatFileSize(0), equals('0 B'));
      expect(FileUtils.formatFileSize(1024), equals('1.0 KB'));
      expect(FileUtils.formatFileSize(1048576), equals('1.0 MB'));
    });

    test('getFileExtension returns correct extension', () {
      expect(FileUtils.getFileExtension('scan_doc_2026.pdf'), equals('pdf'));
      expect(FileUtils.getFileExtension('receipt_image.JPG'), equals('jpg'));
      expect(FileUtils.getFileExtension('no_extension'), equals(''));
    });

    test('getMimeType returns valid MIME type string', () {
      expect(FileUtils.getMimeType('pdf'), equals('application/pdf'));
      expect(FileUtils.getMimeType('jpg'), equals('image/jpeg'));
      expect(FileUtils.getMimeType('png'), equals('image/png'));
    });

    test('generateAutoFileName produces well-formatted prefix and timestamp', () {
      final name = FileUtils.generateAutoFileName(
        prefix: 'ScanX_',
        category: 'Invoices',
        extension: 'pdf',
      );
      expect(name.startsWith('ScanX__Invoices_'), isTrue);
      expect(name.endsWith('.pdf'), isTrue);
    });
  });
}
