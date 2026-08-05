import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../../../../models/folder_item.dart';
import '../../../../services/pdf/pdf_service.dart';

class HomeState {
  final List<DocumentItem> documents;
  final List<FolderItem> folders;
  final bool isLoading;
  final String? selectedFolderId;
  final String? selectedTag;
  final String searchQuery;
  final bool isTrashView;
  final bool isArchiveView;
  final String sortBy; // 'date', 'title', 'size'
  final bool isSelectionMode;
  final Set<String> selectedDocIds;
  final String? errorMessage;
  final String? statusMessage;

  const HomeState({
    this.documents = const [],
    this.folders = const [],
    this.isLoading = false,
    this.selectedFolderId,
    this.selectedTag,
    this.searchQuery = '',
    this.isTrashView = false,
    this.isArchiveView = false,
    this.sortBy = 'date',
    this.isSelectionMode = false,
    this.selectedDocIds = const {},
    this.errorMessage,
    this.statusMessage,
  });

  HomeState copyWith({
    List<DocumentItem>? documents,
    List<FolderItem>? folders,
    bool? isLoading,
    String? selectedFolderId,
    String? selectedTag,
    String? searchQuery,
    bool? isTrashView,
    bool? isArchiveView,
    String? sortBy,
    bool? isSelectionMode,
    Set<String>? selectedDocIds,
    String? errorMessage,
    String? statusMessage,
  }) {
    return HomeState(
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      selectedFolderId: selectedFolderId,
      selectedTag: selectedTag,
      searchQuery: searchQuery ?? this.searchQuery,
      isTrashView: isTrashView ?? this.isTrashView,
      isArchiveView: isArchiveView ?? this.isArchiveView,
      sortBy: sortBy ?? this.sortBy,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedDocIds: selectedDocIds ?? this.selectedDocIds,
      errorMessage: errorMessage,
      statusMessage: statusMessage,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final DocumentRepository _repository;
  final PDFService _pdfService = PDFService();

  HomeController({DocumentRepository? repository})
      : _repository = repository ?? sl<DocumentRepository>(),
        super(const HomeState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final folders = await _repository.getFolders(parentId: state.selectedFolderId);
      final docs = await _repository.getDocuments(
        folderId: state.selectedFolderId,
        tag: state.selectedTag,
        searchQuery: state.searchQuery,
        isTrashed: state.isTrashView,
        isArchived: state.isArchiveView ? true : null,
      );

      // Apply sorting ('date', 'title', 'size')
      docs.sort((a, b) {
        if (state.sortBy == 'title') {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        } else if (state.sortBy == 'size') {
          return b.fileSizeBytes.compareTo(a.fileSizeBytes);
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      state = state.copyWith(
        folders: folders,
        documents: docs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId, isSelectionMode: false, selectedDocIds: {});
    loadData();
  }

  void selectTag(String? tag) {
    state = state.copyWith(selectedTag: tag, isSelectionMode: false, selectedDocIds: {});
    loadData();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    loadData();
  }

  void toggleTrashView() {
    state = state.copyWith(
      isTrashView: !state.isTrashView,
      isArchiveView: false,
      isSelectionMode: false,
      selectedDocIds: {},
    );
    loadData();
  }

  void toggleArchiveView() {
    state = state.copyWith(
      isArchiveView: !state.isArchiveView,
      isTrashView: false,
      isSelectionMode: false,
      selectedDocIds: {},
    );
    loadData();
  }

  // Selection Mode Methods
  void toggleSelectionMode([bool? active]) {
    final nextMode = active ?? !state.isSelectionMode;
    state = state.copyWith(
      isSelectionMode: nextMode,
      selectedDocIds: nextMode ? state.selectedDocIds : {},
    );
  }

  void toggleDocSelection(String docId) {
    final updated = Set<String>.from(state.selectedDocIds);
    if (updated.contains(docId)) {
      updated.remove(docId);
    } else {
      updated.add(docId);
    }
    state = state.copyWith(
      selectedDocIds: updated,
      isSelectionMode: updated.isNotEmpty ? true : state.isSelectionMode,
    );
  }

  void selectAllDocuments() {
    final allIds = state.documents.map((d) => d.id).toSet();
    state = state.copyWith(selectedDocIds: allIds, isSelectionMode: true);
  }

  void deselectAllDocuments() {
    state = state.copyWith(selectedDocIds: {}, isSelectionMode: false);
  }

  Future<void> batchDeleteSelected() async {
    if (state.selectedDocIds.isEmpty) return;
    state = state.copyWith(isLoading: true);
    for (final id in state.selectedDocIds) {
      await _repository.deleteDocument(id, permanent: state.isTrashView);
    }
    state = state.copyWith(
      isSelectionMode: false,
      selectedDocIds: {},
      statusMessage: 'Batch deleted ${state.selectedDocIds.length} documents!',
    );
    await loadData();
  }

  Future<void> batchLockSelected() async {
    if (state.selectedDocIds.isEmpty) return;
    state = state.copyWith(isLoading: true);
    int lockedCount = 0;
    for (final id in state.selectedDocIds) {
      final doc = await _repository.getDocumentById(id);
      if (doc != null) {
        await _repository.saveDocument(doc.copyWith(isLocked: true, updatedAt: DateTime.now()));
        lockedCount++;
      }
    }
    state = state.copyWith(
      isSelectionMode: false,
      selectedDocIds: {},
      statusMessage: 'Moved $lockedCount documents to AES-256 Hidden Vault!',
    );
    await loadData();
  }

  Future<void> batchArchiveSelected() async {
    if (state.selectedDocIds.isEmpty) return;
    state = state.copyWith(isLoading: true);
    int archivedCount = 0;
    for (final id in state.selectedDocIds) {
      final doc = await _repository.getDocumentById(id);
      if (doc != null) {
        await _repository.saveDocument(doc.copyWith(isArchived: true, updatedAt: DateTime.now()));
        archivedCount++;
      }
    }
    state = state.copyWith(
      isSelectionMode: false,
      selectedDocIds: {},
      statusMessage: 'Archived $archivedCount documents to Archive Vault!',
    );
    await loadData();
  }

  Future<String?> batchMergeSelected() async {
    if (state.selectedDocIds.length < 2) return null;
    state = state.copyWith(isLoading: true);
    try {
      final selectedDocs = <DocumentItem>[];
      for (final id in state.selectedDocIds) {
        final d = await _repository.getDocumentById(id);
        if (d != null) selectedDocs.add(d);
      }

      if (selectedDocs.length < 2) {
        state = state.copyWith(isLoading: false, errorMessage: 'Need at least 2 documents to merge.');
        return null;
      }

      final combinedPaths = <String>[];
      String combinedText = '';
      for (final doc in selectedDocs) {
        combinedPaths.addAll(doc.filePaths);
        if (doc.ocrText != null) {
          combinedText += '${doc.ocrText}\n\n--- Merged from ${doc.title} ---\n\n';
        }
      }

      final newPdf = await _pdfService.createPdfFromImages(
        imagePaths: combinedPaths,
        outputFileName: 'batch_merge_${DateTime.now().millisecondsSinceEpoch}',
      );

      final newDocId = DateTime.now().millisecondsSinceEpoch.toString();
      final newDoc = DocumentItem(
        id: newDocId,
        title: 'Batch Merged (${selectedDocs.length} Docs, ${combinedPaths.length}p)',
        folderId: selectedDocs.first.folderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePaths: combinedPaths,
        pdfPath: newPdf.path,
        ocrText: combinedText.trim(),
        pageCount: combinedPaths.length,
        fileSizeBytes: await newPdf.exists() ? await newPdf.length() : 1024 * combinedPaths.length,
        tags: const ['Batch Merged', 'Sardar Haseeb Technologies'],
      );

      await _repository.saveDocument(newDoc);

      state = state.copyWith(
        isSelectionMode: false,
        selectedDocIds: {},
        statusMessage: 'Batch merged ${selectedDocs.length} documents into new document "${newDoc.title}"!',
      );
      await loadData();
      return newDocId;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Batch merge failed: $e');
      return null;
    }
  }

  Future<void> toggleFavorite(DocumentItem doc) async {
    final updated = doc.copyWith(isFavorite: !doc.isFavorite);
    await _repository.saveDocument(updated);
    await loadData();
  }

  Future<void> toggleArchive(DocumentItem doc) async {
    final updated = doc.copyWith(
      isArchived: !doc.isArchived,
      updatedAt: DateTime.now(),
    );
    await _repository.saveDocument(updated);
    await loadData();
  }

  Future<void> toggleLock(DocumentItem doc) async {
    final updated = doc.copyWith(isLocked: !doc.isLocked);
    await _repository.saveDocument(updated);
    await loadData();
  }

  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id, permanent: state.isTrashView);
    await loadData();
  }

  Future<void> restoreDocument(String id) async {
    await _repository.restoreDocument(id);
    await loadData();
  }

  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await loadData();
  }

  Future<void> createFolder(String name, String colorHex, {String? parentId}) async {
    final newFolder = FolderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      parentId: parentId ?? state.selectedFolderId,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveFolder(newFolder);
    await loadData();
  }
}

final homeProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController();
});

/// Independent browser instance powering the "All Documents" tab so its
/// filters/folder navigation never disturb the Home dashboard view.
final documentsBrowserProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController();
});
