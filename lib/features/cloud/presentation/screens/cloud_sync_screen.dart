import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../controllers/cloud_sync_controller.dart';

class CloudSyncScreen extends ConsumerWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudSyncProvider);
    final controller = ref.read(cloudSyncProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Cloud Vault', subtitle: 'Encrypted • Auto-sync'),
      body: Stack(
        children: [
          Positioned(top: -60, left: -40, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.cyanGradient.colors.first.withOpacity(0.12), Colors.transparent])))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: AppSpacing.cardShadowDark,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: AppColors.cyanGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.cyanGradient.colors.first.withOpacity(0.35), blurRadius: 18)]), child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 42)),
                          Positioned(top: 2, right: 2, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(gradient: AppColors.emeraldGradient, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 12))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Files secured & backed up', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Last sync: ${state.lastSyncedTime}', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                      const SizedBox(height: 18),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Storage', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)), Text('4.25 GB / 15 GB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]),
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: 0.283, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.08), valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark))),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: state.isBackingUp ? null : () => controller.backupToCloud(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 16)]),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [state.isBackingUp ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Text(state.isBackingUp ? 'Backing up...' : 'Backup Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (state.statusMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.success.withOpacity(0.15), AppColors.success.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withOpacity(0.25))),
                    child: Row(children: [Container(width: 24, height: 24, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.22), shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14)), const SizedBox(width: 10), Expanded(child: Text(state.statusMessage!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.success)))]),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryDark.withOpacity(0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryDark.withOpacity(0.18))),
                  child: Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primaryDark.withOpacity(0.22), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_rounded, color: AppColors.primaryDark, size: 16)), const SizedBox(width: 10), const Expanded(child: Text('Timestamp-based conflict resolution • Offline edits merge automatically', style: TextStyle(color: Color(0xFF8B94B8), fontSize: 11.5, height: 1.4)))]),
                ),
                const SizedBox(height: 20),
                const Text('Connected Vaults', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                _CloudCard(title: 'Google Drive', subtitle: 'Auto daily • Encrypted', icon: Icons.add_to_drive_rounded, gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF357AE8)]), isConnected: state.isGoogleDriveConnected, onToggle: () => controller.toggleProvider('Google Drive')),
                _CloudCard(title: 'Dropbox', subtitle: 'Vault backup • Secure', icon: Icons.folder_shared_rounded, gradient: const LinearGradient(colors: [Color(0xFF0061FF), Color(0xFF004EC2)]), isConnected: state.isDropboxConnected, onToggle: () => controller.toggleProvider('Dropbox')),
                _CloudCard(title: 'OneDrive', subtitle: 'Enterprise integration', icon: Icons.cloud_queue_rounded, gradient: const LinearGradient(colors: [Color(0xFF0078D4), Color(0xFF005A9E)]), isConnected: state.isOneDriveConnected, onToggle: () => controller.toggleProvider('OneDrive')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Gradient gradient;
  final bool isConnected;
  final VoidCallback onToggle;
  const _CloudCard({required this.title, required this.subtitle, required this.icon, required this.gradient, required this.isConnected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: isConnected ? AppColors.success : AppColors.textSecondaryDark, fontSize: 11.5, fontWeight: isConnected ? FontWeight.w600 : FontWeight.w400))])),
          Switch(value: isConnected, activeColor: AppColors.primaryDark, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }
}
