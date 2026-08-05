import '../../models/document_item.dart';
import '../../models/folder_item.dart';

abstract class DocumentRepository {
  // Documents
  Future<List<DocumentItem>> getDocuments({
    String? folderId,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    String? tag,
    String? searchQuery,
  });
  Future<DocumentItem?> getDocumentById(String id);
  Future<void> saveDocument(DocumentItem document);
  Future<void> deleteDocument(String id, {bool permanent = false});
  Future<void> restoreDocument(String id);
  Future<void> emptyTrash();

  // Folders
  Future<List<FolderItem>> getFolders({String? parentId});
  Future<FolderItem?> getFolderById(String id);
  Future<void> saveFolder(FolderItem folder);
  Future<void> deleteFolder(String id);

  // Sync
  Future<void> syncWithCloud();
}
