import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../domain/repositories/ai_repository.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../../../../models/ocr_result.dart';

class OCRState {
  final DocumentItem? document;
  final OCRResult? ocrResult;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? translatedText;
  final bool isTranslating;
  final bool isEditing;
  final String editableText;
  final bool isSaving;

  const OCRState({
    this.document,
    this.ocrResult,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.translatedText,
    this.isTranslating = false,
    this.isEditing = false,
    this.editableText = '',
    this.isSaving = false,
  });

  OCRState copyWith({
    DocumentItem? document,
    OCRResult? ocrResult,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? translatedText,
    bool? isTranslating,
    bool? isEditing,
    String? editableText,
    bool? isSaving,
  }) {
    return OCRState(
      document: document ?? this.document,
      ocrResult: ocrResult ?? this.ocrResult,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      translatedText: translatedText ?? this.translatedText,
      isTranslating: isTranslating ?? this.isTranslating,
      isEditing: isEditing ?? this.isEditing,
      editableText: editableText ?? this.editableText,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class OCRController extends StateNotifier<OCRState> {
  final DocumentRepository _documentRepo;
  final AIRepository _aiRepo;

  OCRController({DocumentRepository? documentRepo, AIRepository? aiRepo})
      : _documentRepo = documentRepo ?? sl<DocumentRepository>(),
        _aiRepo = aiRepo ?? sl<AIRepository>(),
        super(const OCRState());

  Future<void> loadDocument(String documentId) async {
    state = state.copyWith(isLoading: true);
    try {
      final doc = await _documentRepo.getDocumentById(documentId);
      if (doc == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Document not found.');
        return;
      }

      final text = doc.ocrText ?? 'No OCR text available for this scan.';
      final ocrResult = await _aiRepo.extractEntities(text);

      state = state.copyWith(
        document: doc,
        ocrResult: ocrResult,
        editableText: text,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleEditMode() {
    state = state.copyWith(
      isEditing: !state.isEditing,
      editableText: state.ocrResult?.text ?? state.document?.ocrText ?? '',
    );
  }

  void updateEditableText(String newText) {
    state = state.copyWith(editableText: newText);
  }

  Future<void> saveEditedText() async {
    if (state.document == null) return;
    state = state.copyWith(isSaving: true);
    try {
      final updatedText = state.editableText;
      final updatedDoc = state.document!.copyWith(
        ocrText: updatedText,
        updatedAt: DateTime.now(),
      );
      await _documentRepo.saveDocument(updatedDoc);

      final newEntities = await _aiRepo.extractEntities(updatedText);

      state = state.copyWith(
        document: updatedDoc,
        ocrResult: newEntities,
        isEditing: false,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save updated text.');
    }
  }

  Future<void> translateText(String targetLanguage) async {
    final text = state.ocrResult?.text ?? state.document?.ocrText;
    if (text == null || text.isEmpty) return;

    state = state.copyWith(isTranslating: true);
    try {
      final analysis = await _aiRepo.analyzeDocument(
        ocrText: text,
        promptType: 'translate',
        targetLanguage: targetLanguage,
      );
      state = state.copyWith(
        translatedText: analysis.translatedText ?? 'Translation complete.',
        isTranslating: false,
      );
    } catch (e) {
      state = state.copyWith(isTranslating: false, errorMessage: 'Translation failed.');
    }
  }

  Future<void> copyTextToClipboard() async {
    final text = state.translatedText ?? state.ocrResult?.text ?? state.document?.ocrText ?? '';
    await Clipboard.setData(ClipboardData(text: text));
  }
}

final ocrProvider = StateNotifierProvider.family<OCRController, OCRState, String>((ref, docId) {
  final controller = OCRController();
  controller.loadDocument(docId);
  return controller;
});
