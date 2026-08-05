import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../services/cloud/cloud_sync_service.dart';

class CloudSyncState {
  final SyncStatus status;
  final bool isGoogleDriveConnected;
  final bool isDropboxConnected;
  final bool isOneDriveConnected;
  final String? lastSyncedTime;
  final bool isBackingUp;
  final bool isRestoring;
  final String? statusMessage;

  const CloudSyncState({
    this.status = SyncStatus.idle,
    this.isGoogleDriveConnected = false,
    this.isDropboxConnected = false,
    this.isOneDriveConnected = false,
    this.lastSyncedTime,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.statusMessage,
  });

  CloudSyncState copyWith({
    SyncStatus? status,
    bool? isGoogleDriveConnected,
    bool? isDropboxConnected,
    bool? isOneDriveConnected,
    String? lastSyncedTime,
    bool? isBackingUp,
    bool? isRestoring,
    String? statusMessage,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      isGoogleDriveConnected: isGoogleDriveConnected ?? this.isGoogleDriveConnected,
      isDropboxConnected: isDropboxConnected ?? this.isDropboxConnected,
      isOneDriveConnected: isOneDriveConnected ?? this.isOneDriveConnected,
      lastSyncedTime: lastSyncedTime ?? this.lastSyncedTime,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      statusMessage: statusMessage,
    );
  }
}

class CloudSyncController extends StateNotifier<CloudSyncState> {
  final CloudSyncService _syncService;
  late final StreamSubscription<SyncStatus> _syncSub;

  CloudSyncController({CloudSyncService? syncService})
      : _syncService = syncService ?? sl<CloudSyncService>(),
        super(const CloudSyncState()) {
    _syncSub = _syncService.syncStatusStream.listen((status) {
      if (!mounted) return;
      state = state.copyWith(status: status);
      if (status == SyncStatus.synced) {
        state = state.copyWith(lastSyncedTime: 'Just now');
      }
    });
  }

  Future<void> triggerSync() async {
    state = state.copyWith(status: SyncStatus.syncing, statusMessage: 'Synchronizing documents...');
    await _syncService.syncAll();
    if (!mounted) return;
    final synced = _syncService.currentStatus == SyncStatus.synced;
    state = state.copyWith(
      status: _syncService.currentStatus,
      lastSyncedTime: synced ? 'Just now' : state.lastSyncedTime,
      statusMessage: synced ? 'Cloud sync complete!' : 'Cloud sync is offline until Firebase sign-in is available.',
    );
  }

  Future<void> backupToCloud() async {
    state = state.copyWith(isBackingUp: true, statusMessage: 'Backing up vault to encrypted cloud storage...');
    await _syncService.syncAll();
    if (!mounted) return;
    final synced = _syncService.currentStatus == SyncStatus.synced;
    state = state.copyWith(
      isBackingUp: false,
      status: _syncService.currentStatus,
      lastSyncedTime: synced ? 'Backup verified • Just now' : state.lastSyncedTime,
      statusMessage: synced ? 'Successfully backed up documents to Cloud Vault!' : 'Backup queued locally. Sign in to Firebase cloud sync to upload.',
    );
  }

  Future<void> restoreFromCloud() async {
    state = state.copyWith(isRestoring: true, statusMessage: 'Restoring documents from Cloud Vault...');
    await _syncService.syncAll();
    if (!mounted) return;
    final synced = _syncService.currentStatus == SyncStatus.synced;
    state = state.copyWith(
      isRestoring: false,
      status: _syncService.currentStatus,
      lastSyncedTime: synced ? 'Restored from cloud • Just now' : state.lastSyncedTime,
      statusMessage: synced ? 'Successfully restored documents and folders from Cloud Vault!' : 'Restore unavailable while cloud account is offline.',
    );
  }

  Future<void> toggleProvider(String providerName) async {
    final isConnected = await _syncService.connectProvider(providerName);
    if (!mounted) return;
    final message = isConnected
        ? 'Connected $providerName backup channel'
        : '$providerName OAuth is not configured. Firebase cloud sync remains available when signed in.';

    if (providerName == 'Google Drive') {
      state = state.copyWith(isGoogleDriveConnected: isConnected, statusMessage: message);
    } else if (providerName == 'Dropbox') {
      state = state.copyWith(isDropboxConnected: isConnected, statusMessage: message);
    } else if (providerName == 'OneDrive') {
      state = state.copyWith(isOneDriveConnected: isConnected, statusMessage: message);
    }
  }

  @override
  void dispose() {
    _syncSub.cancel();
    super.dispose();
  }
}

final cloudSyncProvider = StateNotifierProvider<CloudSyncController, CloudSyncState>((ref) {
  return CloudSyncController();
});
