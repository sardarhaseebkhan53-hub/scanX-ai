import '../../models/document_item.dart';
import '../../models/folder_item.dart';
import '../../services/storage/local_storage_service.dart';

class HiveLocalDataSource {
  final LocalStorageService _localStorageService;

  HiveLocalDataSource({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService;

  Future<List<DocumentItem>> getDocuments() => _localStorageService.getAllDocuments();
  Future<DocumentItem?> getDocumentById(String id) => _localStorageService.getDocument(id);
  Future<void> saveDocument(DocumentItem document) => _localStorageService.saveDocument(document);
  Future<void> deleteDocument(String id) => _localStorageService.deleteDocument(id);

  Future<List<FolderItem>> getFolders() => _localStorageService.getAllFolders();
  Future<FolderItem?> getFolderById(String id) => _localStorageService.getFolder(id);
  Future<void> saveFolder(FolderItem folder) => _localStorageService.saveFolder(folder);
  Future<void> deleteFolder(String id) => _localStorageService.deleteFolder(id);
}
