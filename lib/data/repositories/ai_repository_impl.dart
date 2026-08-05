import '../../domain/repositories/ai_repository.dart';
import '../../models/ai_analysis_result.dart';
import '../../models/ocr_result.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ocr/ocr_service.dart';

class AIRepositoryImpl implements AIRepository {
  final AIService _aiService;
  final OCRService _ocrService;

  AIRepositoryImpl({
    required AIService aiService,
    required OCRService ocrService,
  })  : _aiService = aiService,
        _ocrService = ocrService;

  @override
  Future<AIAnalysisResult> analyzeDocument({
    required String ocrText,
    required String promptType,
    String? targetLanguage,
  }) async {
    return await _aiService.analyzeText(ocrText, promptType, targetLanguage: targetLanguage);
  }

  @override
  Future<String> chatWithDocument({
    required String documentText,
    required String userMessage,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    return await _aiService.chatWithDocument(documentText, userMessage, chatHistory);
  }

  @override
  Future<OCRResult> extractEntities(String text) async {
    return await _ocrService.extractEntitiesFromText(text);
  }

  @override
  Future<String> suggestFileName(String ocrText) async {
    return await _aiService.autoGenerateTitle(ocrText);
  }

  @override
  Future<String> suggestFolder(String ocrText, List<String> availableFolderNames) async {
    return await _aiService.suggestFolder(ocrText, availableFolderNames);
  }
}
