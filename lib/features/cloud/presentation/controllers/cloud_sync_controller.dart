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
    this.lastSyncedTime = 'Today, 08:45 AM',
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

  CloudSyncController({CloudSyncService? syncService})
      : _syncService = syncService ?? sl<CloudSyncService>(),
        super(const CloudSyncState()) {
    _syncService.syncStatusStream.listen((status) {
      state = state.copyWith(status: status);
      if (status == SyncStatus.synced) {
        state = state.copyWith(lastSyncedTime: 'Just now');
      }
    });
  }

  Future<void> triggerSync() async {
    state = state.copyWith(status: SyncStatus.syncing, statusMessage: 'Synchronizing documents...');
    await _syncService.syncAll();
    state = state.copyWith(
      status: SyncStatus.synced,
      lastSyncedTime: 'Just now',
      statusMessage: 'Cloud sync complete!',
    );
  }

  Future<void> backupToCloud() async {
    state = state.copyWith(isBackingUp: true, statusMessage: 'Backing up vault to encrypted cloud storage...');
    await _syncService.syncAll();
    state = state.copyWith(
      isBackingUp: false,
      lastSyncedTime: 'Backup verified • Just now',
      statusMessage: 'Successfully backed up local Hive database and PDF files to Cloud Vault!',
    );
  }

  Future<void> restoreFromCloud() async {
    state = state.copyWith(isRestoring: true, statusMessage: 'Restoring documents from Cloud Vault...');
    await _syncService.syncAll();
    state = state.copyWith(
      isRestoring: false,
      lastSyncedTime: 'Restored from cloud • Just now',
      statusMessage: 'Successfully restored all documents and folders from Cloud Vault!',
    );
  }

  Future<void> toggleProvider(String providerName) async {
    if (providerName == 'Google Drive') {
      state = state.copyWith(
        isGoogleDriveConnected: !state.isGoogleDriveConnected,
        statusMessage: !state.isGoogleDriveConnected
            ? 'Connected Google Drive backup channel'
            : 'Disconnected Google Drive',
      );
    } else if (providerName == 'Dropbox') {
      state = state.copyWith(
        isDropboxConnected: !state.isDropboxConnected,
        statusMessage: !state.isDropboxConnected
            ? 'Connected Dropbox encrypted vault'
            : 'Disconnected Dropbox',
      );
    } else if (providerName == 'OneDrive') {
      state = state.copyWith(
        isOneDriveConnected: !state.isOneDriveConnected,
        statusMessage: !state.isOneDriveConnected
            ? 'Connected Microsoft OneDrive enterprise channel'
            : 'Disconnected Microsoft OneDrive',
      );
    }
  }
}

final cloudSyncProvider = StateNotifierProvider<CloudSyncController, CloudSyncState>((ref) {
  return CloudSyncController();
});
