import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:scanx_ai/core/utils/crypto_utils.dart';
import 'package:scanx_ai/core/utils/file_utils.dart';
import 'package:scanx_ai/models/document_item.dart';
import 'package:scanx_ai/services/ai/ai_service.dart';
import 'package:scanx_ai/services/ocr/ocr_service.dart';

void main() {
  group('ScanX AI End-to-End Integration Flow Tests', () {
    late PluggableAIService aiService;
    late OCRService ocrService;

    setUp(() {
      aiService = PluggableAIService(dio: Dio(), provider: 'gemini');
      ocrService = OCRService();
    });

    test('Full document lifecycle: OCR recognition -> AI executive summary -> PIN hash vault validation', () async {
      // 1. Simulate OCR Text Extraction from raw scan
      const rawScannedText =
          'INVOICE #INV-2026-08942\nVendor: Sardar Haseeb Technologies\nDate: 2026-08-02\nContact: support@sardarhaseeb.com\nTotal Amount Due: \$1566.00';
      final ocrResult = await ocrService.extractEntitiesFromText(rawScannedText);

      expect(ocrResult.extractedEmails, contains('support@sardarhaseeb.com'));
      expect(ocrResult.extractedDates, contains('2026-08-02'));

      // 2. Run Pluggable AI Service to generate invoice metadata and title
      final aiAnalysis = await aiService.analyzeText(rawScannedText, 'invoice');
      expect(aiAnalysis.invoiceNumber, equals('INV-2026-08942'));
      expect(aiAnalysis.totalAmount, equals(1566.00));
      expect(aiAnalysis.suggestedTitle, isNotNull);

      // 3. Construct DocumentItem and check serialization
      final doc = DocumentItem(
        id: 'doc_integration_01',
        title: aiAnalysis.suggestedTitle ?? 'Invoice Scan',
        folderId: 'invoices',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePaths: ['/storage/emulated/0/scanx/page1.jpg'],
        pdfPath: '/storage/emulated/0/scanx/doc_integration_01.pdf',
        ocrText: rawScannedText,
        isLocked: true,
        aiSummary: 'Invoice for \$1566.00 from Sardar Haseeb Technologies',
      );

      final map = doc.toMap();
      final restoredDoc = DocumentItem.fromMap(map);
      expect(restoredDoc.id, equals(doc.id));
      expect(restoredDoc.isLocked, isTrue);

      // 4. Secure Keystore PIN hash verification
      const masterPin = '9876';
      final hashedPin = CryptoUtils.hashPin(masterPin);
      expect(CryptoUtils.verifyPin('9876', hashedPin), isTrue);
      expect(CryptoUtils.verifyPin('0000', hashedPin), isFalse);

      // 5. Check automated filename generation
      final generatedFileName = FileUtils.generateAutoFileName(
        prefix: 'ScanX_Invoice_',
        category: 'Enterprise',
        extension: 'pdf',
      );
      expect(generatedFileName.contains('ScanX_Invoice__Enterprise_'), isTrue);
      expect(generatedFileName.endsWith('.pdf'), isTrue);
    });
  });
}
