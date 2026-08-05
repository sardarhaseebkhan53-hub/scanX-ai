import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../domain/repositories/ai_repository.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/ai_analysis_result.dart';
import '../../../../models/document_item.dart';
import '../../../../services/ai/ai_service.dart';

class AIState {
  final DocumentItem? document;
  final bool isLoading;
  final bool isAnalyzing;
  final String? errorMessage;
  final AIAnalysisResult? analysisResult;
  final List<Map<String, String>> chatMessages;
  final String? suggestedFolderName;
  final List<String> autoTags;

  const AIState({
    this.document,
    this.isLoading = false,
    this.isAnalyzing = false,
    this.errorMessage,
    this.analysisResult,
    this.chatMessages = const [],
    this.suggestedFolderName,
    this.autoTags = const [],
  });

  AIState copyWith({
    DocumentItem? document,
    bool? isLoading,
    bool? isAnalyzing,
    String? errorMessage,
    AIAnalysisResult? analysisResult,
    List<Map<String, String>>? chatMessages,
    String? suggestedFolderName,
    List<String>? autoTags,
  }) {
    return AIState(
      document: document ?? this.document,
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage,
      analysisResult: analysisResult ?? this.analysisResult,
      chatMessages: chatMessages ?? this.chatMessages,
      suggestedFolderName: suggestedFolderName ?? this.suggestedFolderName,
      autoTags: autoTags ?? this.autoTags,
    );
  }
}

class AIController extends StateNotifier<AIState> {
  final DocumentRepository _documentRepo;
  final AIRepository _aiRepo;

  AIController({DocumentRepository? documentRepo, AIRepository? aiRepo})
      : _documentRepo = documentRepo ?? sl<DocumentRepository>(),
        _aiRepo = aiRepo ?? sl<AIRepository>(),
        super(const AIState());

  Future<void> init(String? documentId) async {
    if (documentId == null || documentId.isEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      final doc = await _documentRepo.getDocumentById(documentId);
      if (doc == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Document not found.');
        return;
      }

      state = state.copyWith(document: doc, isLoading: false);
      // Automatically generate summary and semantic keywords
      await runAnalysis('summary');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> runAnalysis(String promptType) async {
    final text = state.document?.ocrText;
    if (text == null || text.isEmpty) return;

    state = state.copyWith(isAnalyzing: true);
    try {
      final res = await _aiRepo.analyzeDocument(ocrText: text, promptType: promptType);
      final folderSuggest = await _aiRepo.suggestFolder(text, ['Invoices', 'Receipts', 'Legal', 'Personal']);

      // Extract semantic keywords and tags
      final aiService = sl<AIService>();
      final tags = await aiService.extractKeywordsAndTags(text);

      state = state.copyWith(
        analysisResult: res,
        suggestedFolderName: folderSuggest,
        autoTags: tags,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, errorMessage: 'Analysis failed: $e');
    }
  }

  Future<void> analyzeReceiptOrInvoice({bool isInvoice = false}) async {
    state = state.copyWith(isAnalyzing: true);
    try {
      if (state.document?.ocrText != null && state.document!.ocrText!.trim().isNotEmpty) {
        final res = await _aiRepo.analyzeDocument(
          ocrText: state.document!.ocrText!,
          promptType: isInvoice ? 'invoice' : 'receipt',
        );
        state = state.copyWith(analysisResult: res, isAnalyzing: false);
      } else {
        // Load mock receipt/invoice data from assets if no OCR text
        final jsonPath = isInvoice
            ? 'assets/mock/sample_invoice.json'
            : 'assets/mock/sample_receipt.json';
        final jsonStr = await rootBundle.loadString(jsonPath);
        final map = jsonDecode(jsonStr);
        state = state.copyWith(
          analysisResult: AIAnalysisResult.fromMap(map),
          isAnalyzing: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, errorMessage: e.toString());
    }
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    final updatedMessages = List<Map<String, String>>.from(state.chatMessages)
      ..add({'role': 'user', 'content': message});
    state = state.copyWith(chatMessages: updatedMessages, isAnalyzing: true);

    try {
      final text = state.document?.ocrText ?? 'No document text loaded.';
      final reply = await _aiRepo.chatWithDocument(
        documentText: text,
        userMessage: message,
        chatHistory: updatedMessages,
      );

      final nextMessages = List<Map<String, String>>.from(updatedMessages)
        ..add({'role': 'assistant', 'content': reply});
      state = state.copyWith(chatMessages: nextMessages, isAnalyzing: false);
    } catch (e) {
      final nextMessages = List<Map<String, String>>.from(updatedMessages)
        ..add({'role': 'assistant', 'content': 'Error communicating with AI Assistant: $e'});
      state = state.copyWith(chatMessages: nextMessages, isAnalyzing: false);
    }
  }
}

final aiProvider = StateNotifierProvider.family<AIController, AIState, String?>((ref, docId) {
  final controller = AIController();
  controller.init(docId);
  return controller;
});
