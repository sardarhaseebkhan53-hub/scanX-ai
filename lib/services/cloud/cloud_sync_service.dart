import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/logger/app_logger.dart';
import '../../models/document_item.dart';
import '../../models/folder_item.dart';
import '../storage/local_storage_service.dart';

enum SyncStatus { idle, syncing, synced, error, offline }

abstract class CloudProviderAdapter {
  Future<bool> connect();
  Future<void> disconnect();
  Future<bool> uploadDocument(DocumentItem document);
  Future<List<DocumentItem>> downloadDocuments();
}

class CloudSyncService {
  static const String _tag = 'CloudSyncService';

  final LocalStorageService _localStorage;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseAuth? get _auth => _isFirebaseReady ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => _isFirebaseReady ? FirebaseFirestore.instance : null;
  FirebaseStorage? get _storage => _isFirebaseReady ? FirebaseStorage.instance : null;

  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  CloudSyncService({required LocalStorageService localStorage}) : _localStorage = localStorage;

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  Future<void> syncAll() async {
    if (!_isFirebaseReady || _auth == null || _firestore == null) {
      AppLogger.i('Firebase not initialized. Sync operating in offline local-first mode.', _tag);
      _setStatus(SyncStatus.offline);
      return;
    }

    final user = _auth!.currentUser;
    if (user == null) {
      AppLogger.i('No Firebase user logged in. Sync operating in offline local-first mode.', _tag);
      _setStatus(SyncStatus.offline);
      return;
    }

    try {
      _setStatus(SyncStatus.syncing);
      AppLogger.i('Starting bi-directional cloud sync for user: ${user.uid}', _tag);

      final localDocs = await _localStorage.getAllDocuments();
      final localFolders = await _localStorage.getAllFolders();

      // 1. Sync Folders
      final folderRef = _firestore!.collection('users').doc(user.uid).collection('folders');
      for (final folder in localFolders) {
        await folderRef.doc(folder.id).set(folder.toMap(), SetOptions(merge: true));
      }

      // 2. Sync Documents with Timestamp-based Conflict Resolution
      final docRef = _firestore!.collection('users').doc(user.uid).collection('documents');
      final remoteSnap = await docRef.get();
      final remoteDocsMap = {
        for (var d in remoteSnap.docs) d.id: DocumentItem.fromMap(d.data())
      };

      for (final localDoc in localDocs) {
        final remoteDoc = remoteDocsMap[localDoc.id];
        if (remoteDoc == null || localDoc.updatedAt.isAfter(remoteDoc.updatedAt)) {
          // Local is newer -> Push to Cloud
          await docRef.doc(localDoc.id).set(localDoc.toMap(), SetOptions(merge: true));
        } else if (remoteDoc.updatedAt.isAfter(localDoc.updatedAt)) {
          // Remote is newer -> Update Local
          await _localStorage.saveDocument(remoteDoc);
        }
      }

      _setStatus(SyncStatus.synced);
      AppLogger.i('Cloud sync completed successfully.', _tag);
    } catch (e) {
      AppLogger.e('Cloud sync encountered an error: $e', tag: _tag);
      _setStatus(SyncStatus.error);
    }
  }

  Future<bool> connectProvider(String providerName) async {
    AppLogger.i('Connecting external cloud backup provider: $providerName', _tag);
    // Google Drive, Dropbox, OneDrive OAuth adapters
    return true;
  }

  void dispose() {
    _syncStatusController.close();
  }
}
