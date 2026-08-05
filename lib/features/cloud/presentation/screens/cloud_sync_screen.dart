import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/cloud/cloud_sync_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../controllers/cloud_sync_controller.dart';

class CloudSyncScreen extends ConsumerWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudSyncProvider);
    final controller = ref.read(cloudSyncProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Cloud Backup & Sync'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cloud Banner matching & surpassing image
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary.withOpacity(0.14), const Color(0xFF10B981).withOpacity(0.14)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_done_rounded, color: colorScheme.primary, size: 52),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your files are safe and backed up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last Synchronized: ${state.lastSyncedTime}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Storage Progress Bar (4.25 GB / 15 GB)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Storage Used',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '4.25 GB / 15 GB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 4.25 / 15.0,
                          minHeight: 10,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // "Backup Now" primary button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: state.isBackingUp ? null : () => controller.backupToCloud(),
                      icon: state.isBackingUp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(state.isBackingUp ? 'Backing up...' : 'Backup Now'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: state.isRestoring ? null : () => controller.restoreFromCloud(),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(state.isRestoring ? 'Restoring...' : 'Restore from Vault'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Status message banner
            if (state.statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.statusMessage!,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Conflict Resolution Explanation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ScanX AI uses timestamp-based conflict resolution. If you edit offline, changes merge automatically when reconnected.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. External Cloud Backups (Drive, Dropbox, OneDrive) matching image
            const Text(
              'Connected Backup Vaults',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCloudCard(
              context: context,
              title: 'Google Drive',
              subtitle: 'Connected • Automatic daily PDF & Hive backup',
              icon: Icons.add_to_drive_rounded,
              color: const Color(0xFF4285F4),
              isConnected: state.isGoogleDriveConnected,
              onToggle: () => controller.toggleProvider('Google Drive'),
            ),
            _buildCloudCard(
              context: context,
              title: 'Dropbox',
              subtitle: 'Connected • Encrypted document vault backup',
              icon: Icons.folder_shared_rounded,
              color: const Color(0xFF0061FF),
              isConnected: state.isDropboxConnected,
              onToggle: () => controller.toggleProvider('Dropbox'),
            ),
            _buildCloudCard(
              context: context,
              title: 'Microsoft OneDrive',
              subtitle: 'Connected • Enterprise corporate cloud integration',
              icon: Icons.cloud_queue_rounded,
              color: const Color(0xFF0078D4),
              isConnected: state.isOneDriveConnected,
              onToggle: () => controller.toggleProvider('OneDrive'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isConnected,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected ? Colors.green : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: (_) => onToggle(),
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
