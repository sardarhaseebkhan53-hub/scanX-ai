import '../../services/cloud/cloud_sync_service.dart';

class FirebaseCloudDataSource {
  final CloudSyncService _cloudSyncService;

  FirebaseCloudDataSource({required CloudSyncService cloudSyncService})
      : _cloudSyncService = cloudSyncService;

  Future<void> syncCloud() => _cloudSyncService.syncAll();
  Stream<SyncStatus> get syncStatusStream => _cloudSyncService.syncStatusStream;
}
