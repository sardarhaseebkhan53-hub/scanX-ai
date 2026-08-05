import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/models/document_item.dart';

void main() {
  group('DocumentItem Domain Model Tests', () {
    final now = DateTime.now();
    final sampleDoc = DocumentItem(
      id: 'doc_101',
      title: 'Enterprise Contract 2026',
      folderId: 'contracts',
      createdAt: now,
      updatedAt: now,
      filePaths: ['/tmp/page1.jpg', '/tmp/page2.jpg'],
      pdfPath: '/tmp/doc_101.pdf',
      ocrText: 'CONFIDENTIAL AGREEMENT CLAUSE 1',
      tags: const ['Legal', '2026'],
      isFavorite: true,
      isLocked: false,
      pageCount: 2,
      fileSizeBytes: 204800,
    );

    test('toMap and fromMap perform lossless serialization', () {
      final map = sampleDoc.toMap();
      final decodedDoc = DocumentItem.fromMap(map);

      expect(decodedDoc.id, equals(sampleDoc.id));
      expect(decodedDoc.title, equals(sampleDoc.title));
      expect(decodedDoc.filePaths.length, equals(2));
      expect(decodedDoc.tags, contains('Legal'));
      expect(decodedDoc.isFavorite, isTrue);
    });

    test('copyWith updates specified fields while keeping immutability', () {
      final lockedDoc = sampleDoc.copyWith(isLocked: true, title: 'Locked Contract');
      expect(lockedDoc.isLocked, isTrue);
      expect(lockedDoc.title, equals('Locked Contract'));
      expect(lockedDoc.id, equals(sampleDoc.id));
      expect(sampleDoc.isLocked, isFalse); // original unmodified
    });
  });
}
