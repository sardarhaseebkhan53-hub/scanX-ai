import '../../domain/repositories/document_repository.dart';
import '../../models/document_item.dart';
import '../../models/folder_item.dart';
import '../datasources/firebase_cloud_datasource.dart';
import '../datasources/hive_local_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final HiveLocalDataSource _localDataSource;
  final FirebaseCloudDataSource _cloudDataSource;

  DocumentRepositoryImpl({
    required HiveLocalDataSource localDataSource,
    required FirebaseCloudDataSource cloudDataSource,
  })  : _localDataSource = localDataSource,
        _cloudDataSource = cloudDataSource;

  @override
  Future<List<DocumentItem>> getDocuments({
    String? folderId,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    String? tag,
    String? searchQuery,
  }) async {
    final allDocs = await _localDataSource.getDocuments();

    return allDocs.where((doc) {
      if (isTrashed == true && !doc.isTrashed) return false;
      if (isTrashed != true && doc.isTrashed) return false;
      if (folderId != null && doc.folderId != folderId) return false;
      if (isFavorite == true && !doc.isFavorite) return false;
      if (isPinned == true && !doc.isPinned) return false;
      if (isArchived == true && !doc.isArchived) return false;
      if (tag != null && tag.isNotEmpty && !doc.tags.contains(tag)) return false;

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final titleMatches = doc.title.toLowerCase().contains(query);
        final ocrMatches = (doc.ocrText ?? '').toLowerCase().contains(query);
        final tagMatches = doc.tags.any((t) => t.toLowerCase().contains(query));
        if (!titleMatches && !ocrMatches && !tagMatches) return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<DocumentItem?> getDocumentById(String id) async {
    return await _localDataSource.getDocumentById(id);
  }

  @override
  Future<void> saveDocument(DocumentItem document) async {
    final updatedDoc = document.copyWith(updatedAt: DateTime.now());
    await _localDataSource.saveDocument(updatedDoc);
  }

  @override
  Future<void> deleteDocument(String id, {bool permanent = false}) async {
    if (permanent) {
      await _localDataSource.deleteDocument(id);
    } else {
      final doc = await _localDataSource.getDocumentById(id);
      if (doc != null) {
        await _localDataSource.saveDocument(doc.copyWith(isTrashed: true, updatedAt: DateTime.now()));
      }
    }
  }

  @override
  Future<void> restoreDocument(String id) async {
    final doc = await _localDataSource.getDocumentById(id);
    if (doc != null) {
      await _localDataSource.saveDocument(doc.copyWith(isTrashed: false, updatedAt: DateTime.now()));
    }
  }

  @override
  Future<void> emptyTrash() async {
    final allDocs = await _localDataSource.getDocuments();
    for (final doc in allDocs) {
      if (doc.isTrashed) {
        await _localDataSource.deleteDocument(doc.id);
      }
    }
  }

  @override
  Future<List<FolderItem>> getFolders({String? parentId}) async {
    final folders = await _localDataSource.getFolders();
    if (parentId == null) {
      return folders.where((f) => f.parentId == null || f.parentId!.isEmpty).toList();
    }
    return folders.where((f) => f.parentId == parentId).toList();
  }

  @override
  Future<FolderItem?> getFolderById(String id) async {
    return await _localDataSource.getFolderById(id);
  }

  @override
  Future<void> saveFolder(FolderItem folder) async {
    await _localDataSource.saveFolder(folder.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _localDataSource.deleteFolder(id);
  }

  @override
  Future<void> syncWithCloud() async {
    await _cloudDataSource.syncCloud();
  }
}
