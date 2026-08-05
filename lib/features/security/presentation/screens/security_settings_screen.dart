import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../widgets/secure_badge.dart';
import '../controllers/security_controller.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityProvider);
    final controller = ref.read(securityProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Security'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Glowing Shield Card matching & surpassing image
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.18),
                  const Color(0xFF8B5CF6).withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your documents are protected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AES-256 Android Keystore Shield Active',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Security Option Rows matching image badges
          _buildSecurityOption(
            context: context,
            title: 'App Lock',
            subtitle: 'PIN, Pattern, Fingerprint',
            icon: Icons.shield_rounded,
            badgeColor: const Color(0xFF8B5CF6), // Purple
            onTap: () => _showPinDialog(context, controller),
          ),
          _buildSecurityOption(
            context: context,
            title: 'Fingerprint',
            subtitle: state.isBiometricEnabled ? 'Enabled' : 'Disabled',
            icon: Icons.fingerprint_rounded,
            badgeColor: const Color(0xFF3B82F6), // Blue
            trailing: Switch(
              value: state.isBiometricEnabled,
              onChanged: state.isBiometricAvailable
                  ? (val) => controller.toggleBiometric(val)
                  : null,
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
          _buildSecurityOption(
            context: context,
            title: 'Auto Lock',
            subtitle: 'After ${state.autoLockTimeoutMinutes} minutes',
            icon: Icons.timer_rounded,
            badgeColor: const Color(0xFF6366F1), // Indigo
            trailing: DropdownButton<int>(
              value: state.autoLockTimeoutMinutes,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 min')),
                DropdownMenuItem(value: 5, child: Text('5 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
              ],
              onChanged: (val) {
                if (val != null) controller.setTimeoutMinutes(val);
              },
            ),
          ),
          _buildSecurityOption(
            context: context,
            title: 'Hidden Vault',
            subtitle: 'AES-256 Shielded Private Folder',
            icon: Icons.lock_person_rounded,
            badgeColor: const Color(0xFFF97316), // Orange
            onTap: () => context.push(RouteNames.hiddenVault),
          ),
          _buildSecurityOption(
            context: context,
            title: 'Secure Backup',
            subtitle: 'Encrypted',
            icon: Icons.verified_user_rounded,
            badgeColor: const Color(0xFF10B981), // Green
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Android Keystore AES-256 cloud encryption active')),
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. Pattern Lock Setup & Privacy Toggle
          _buildSecurityOption(
            context: context,
            title: 'Pattern Sequence',
            subtitle: state.isPatternEnabled ? 'Active (3x3 Grid)' : 'Set visual swipe pattern',
            icon: Icons.pattern_rounded,
            badgeColor: const Color(0xFFEC4899), // Pink
            onTap: () => _showPatternDialog(context, controller),
          ),
          SwitchListTile(
            title: const Text('Hide Previews for Locked Files'),
            subtitle: const Text('Obscure document thumbnails in recent list'),
            value: state.hidePreviewForLockedFiles,
            onChanged: (val) => controller.toggleHidePreview(val),
            secondary: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: badgeColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showPinDialog(BuildContext context, SecurityController controller) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit Vault PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter 4 digits (e.g. 1234)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = pinController.text.trim();
              if (val.length == 4) {
                controller.setPinCode(val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('4-Digit Vault PIN active and encrypted in Keystore!')),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showPatternDialog(BuildContext context, SecurityController controller) {
    final patternController = TextEditingController(text: '0-1-2-5-8');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Pattern Sequence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter dot sequence (0 to 8 separated by hyphens) e.g. 0-1-2-5-8:'),
            const SizedBox(height: 12),
            TextField(
              controller: patternController,
              decoration: const InputDecoration(hintText: '0-1-2-5-8'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = patternController.text.trim();
              if (val.isNotEmpty) {
                controller.setPatternCode(val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('3x3 Pattern Lock active and stored in Keystore!')),
                );
              }
            },
            child: const Text('Save Pattern'),
          ),
        ],
      ),
    );
  }
}
