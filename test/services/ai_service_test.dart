import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:scanx_ai/services/ai/ai_service.dart';

void main() {
  group('PluggableAIService Unit Tests', () {
    late PluggableAIService aiService;

    setUp(() {
      aiService = PluggableAIService(dio: Dio(), provider: 'gemini');
    });

    test('On-device fallback returns valid executive summary when API key is missing', () async {
      const sampleOcrText =
          'Sardar Haseeb Technologies Enterprise Agreement\nEffective Date: 2026-08-02\nTotal Contract Value: \$120,000 USD\nParties agree to SLAs and encrypted storage compliance.';

      final result = await aiService.analyzeText(sampleOcrText, 'summary');
      expect(result.summary, isNotNull);
      expect(result.summary, contains('Executive Summary'));
      expect(result.suggestedTitle, isNotNull);
    });

    test('On-device fallback parses invoice items into structured AIAnalysisResult', () async {
      const sampleInvoiceText =
          'INVOICE #INV-2026-08942\nVendor: Sardar Haseeb Technologies\nTotal: \$1566.00';

      final result = await aiService.analyzeText(sampleInvoiceText, 'invoice');
      expect(result.invoiceNumber, equals('INV-2026-08942'));
      expect(result.totalAmount, equals(1566.00));
      expect(result.items.isNotEmpty, isTrue);
    });

    test('suggestFolder categorizes OCR text accurately', () async {
      const ocrText = 'TOTAL AMOUNT DUE: \$500.00 INVOICE BILL TO CLIENT';
      final folder = await aiService.suggestFolder(
        ocrText,
        ['Invoices', 'Receipts', 'Legal', 'Personal'],
      );
      expect(folder, equals('Invoices'));
    });
  });
}
