import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';
import '../../models/document_item.dart';
import '../../models/folder_item.dart';
import '../../models/app_settings.dart';

class LocalStorageService {
  static const String _tag = 'LocalStorageService';

  Box<String>? _documentBox;
  Box<String>? _folderBox;
  Box<String>? _settingsBox;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _documentBox = await Hive.openBox<String>(AppConstants.hiveDocumentBox);
      _folderBox = await Hive.openBox<String>(AppConstants.hiveFolderBox);
      _settingsBox = await Hive.openBox<String>(AppConstants.hiveSettingsBox);

      // Create default folders if empty
      if (_folderBox != null && _folderBox!.isEmpty) {
        await _createDefaultFolders();
      }

      AppLogger.i('Hive local storage initialized successfully.', _tag);
    } catch (e) {
      AppLogger.e('Failed to initialize Hive local storage: $e', tag: _tag);
    }
  }

  Future<void> _createDefaultFolders() async {
    final now = DateTime.now();
    final defaultFolders = [
      FolderItem(id: 'invoices', name: 'Invoices & Bills', colorHex: '#3B82F6', iconName: 'file_invoice', createdAt: now, updatedAt: now),
      FolderItem(id: 'receipts', name: 'Receipts & Expenses', colorHex: '#10B981', iconName: 'receipt', createdAt: now, updatedAt: now),
      FolderItem(id: 'passports', name: 'Passports & ID Cards', colorHex: '#8B5CF6', iconName: 'id_card', createdAt: now, updatedAt: now, isLocked: true),
      FolderItem(id: 'contracts', name: 'Contracts & Legal', colorHex: '#F59E0B', iconName: 'contract', createdAt: now, updatedAt: now),
    ];
    for (final f in defaultFolders) {
      await saveFolder(f);
    }
  }

  // Document Operations
  Future<List<DocumentItem>> getAllDocuments() async {
    if (_documentBox == null) return [];
    final List<DocumentItem> docs = [];
    for (final key in _documentBox!.keys) {
      final jsonStr = _documentBox!.get(key);
      if (jsonStr != null) {
        try {
          docs.add(DocumentItem.fromMap(jsonDecode(jsonStr)));
        } catch (e) {
          AppLogger.w('Failed to decode document key: $key', _tag);
        }
      }
    }
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  Future<DocumentItem?> getDocument(String id) async {
    if (_documentBox == null) return null;
    final jsonStr = _documentBox!.get(id);
    if (jsonStr == null) return null;
    try {
      return DocumentItem.fromMap(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDocument(DocumentItem document) async {
    if (_documentBox == null) return;
    await _documentBox!.put(document.id, jsonEncode(document.toMap()));
  }

  Future<void> deleteDocument(String id) async {
    if (_documentBox == null) return;
    await _documentBox!.delete(id);
  }

  // Folder Operations
  Future<List<FolderItem>> getAllFolders() async {
    if (_folderBox == null) return [];
    final List<FolderItem> folders = [];
    for (final key in _folderBox!.keys) {
      final jsonStr = _folderBox!.get(key);
      if (jsonStr != null) {
        try {
          folders.add(FolderItem.fromMap(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    return folders;
  }

  Future<FolderItem?> getFolder(String id) async {
    if (_folderBox == null) return null;
    final jsonStr = _folderBox!.get(id);
    if (jsonStr == null) return null;
    try {
      return FolderItem.fromMap(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFolder(FolderItem folder) async {
    if (_folderBox == null) return;
    await _folderBox!.put(folder.id, jsonEncode(folder.toMap()));
  }

  Future<void> deleteFolder(String id) async {
    if (_folderBox == null) return;
    await _folderBox!.delete(id);
  }

  // Settings Operations
  Future<AppSettings> getSettings() async {
    if (_settingsBox == null) return const AppSettings();
    final jsonStr = _settingsBox!.get('app_settings');
    if (jsonStr == null) return const AppSettings();
    try {
      return AppSettings.fromMap(jsonDecode(jsonStr));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_settingsBox == null) return;
    await _settingsBox!.put('app_settings', jsonEncode(settings.toMap()));
  }
}
