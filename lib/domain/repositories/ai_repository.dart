import '../../models/ai_analysis_result.dart';
import '../../models/ocr_result.dart';

abstract class AIRepository {
  Future<AIAnalysisResult> analyzeDocument({
    required String ocrText,
    required String promptType, // 'summary', 'explain', 'receipt', 'invoice', 'business_card'
    String? targetLanguage,
  });

  Future<String> chatWithDocument({
    required String documentText,
    required String userMessage,
    List<Map<String, String>> chatHistory = const [],
  });

  Future<OCRResult> extractEntities(String text);

  Future<String> suggestFileName(String ocrText);

  Future<String> suggestFolder(String ocrText, List<String> availableFolderNames);
}
