import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/ad_banner_widget.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../scanner/presentation/widgets/watermark_studio_modal.dart';
import '../controllers/settings_controller.dart';
import 'legal_policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Core Settings
          _buildSettingsRow(
            context: context,
            title: 'Appearance',
            subtitle: 'Dark Mode (${state.themeMode.toUpperCase()})',
            icon: Icons.palette_rounded,
            badgeColor: const Color(0xFFF97316), // Orange
            trailing: DropdownButton<String>(
              value: state.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (val) {
                if (val != null) controller.setThemeMode(val);
              },
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Language',
            subtitle: 'English (${state.languageCode.toUpperCase()})',
            icon: Icons.language_rounded,
            badgeColor: const Color(0xFF3B82F6), // Blue
            onTap: () => _showLanguagePicker(context, controller),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Notifications',
            subtitle: 'Enabled',
            icon: Icons.notifications_active_rounded,
            badgeColor: const Color(0xFFEF4444), // Red
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: const Color(0xFFEF4444),
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Backup & Sync',
            subtitle: 'Firebase • Google Drive • Dropbox',
            icon: Icons.cloud_done_rounded,
            badgeColor: const Color(0xFF06B6D4), // Cyan
            onTap: () => context.push(RouteNames.cloudSync),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Security',
            subtitle: 'PIN, Pattern, Fingerprint Vault',
            icon: Icons.security_rounded,
            badgeColor: const Color(0xFF8B5CF6), // Purple
            onTap: () => context.push(RouteNames.securitySettings),
          ),
          const SizedBox(height: 12),

          // 2. AI Engine & Scanner/Watermark Configuration
          _buildSettingsRow(
            context: context,
            title: 'Pluggable AI Engine',
            subtitle: 'Provider: ${state.aiProvider.toUpperCase()}',
            icon: Icons.auto_awesome,
            badgeColor: const Color(0xFF10B981), // Green
            onTap: () => _showApiKeyDialog(context, controller, state.aiProvider),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Default Watermark Studio',
            subtitle: state.defaultWatermarkConfig.isEnabled
                ? 'Active (${state.defaultWatermarkConfig.position})'
                : 'Disabled',
            icon: Icons.water_drop_rounded,
            badgeColor: const Color(0xFF06B6D4), // Cyan
            onTap: () {
              WatermarkStudioModal.show(
                context,
                initialConfig: state.defaultWatermarkConfig,
                onApply: (config) {
                  controller.updateWatermarkConfig(config);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updated default PDF watermark configuration!')),
                  );
                },
              );
            },
          ),
          _buildSettingsRow(
            context: context,
            title: 'Scanner Auto-Edge',
            subtitle: state.autoEdgeDetection ? 'Enabled' : 'Disabled',
            icon: Icons.crop_free_rounded,
            badgeColor: const Color(0xFF6366F1), // Indigo
            trailing: Switch(
              value: state.autoEdgeDetection,
              onChanged: (val) => controller.toggleAutoEdge(val),
              activeColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Legal & Compliance Section
          _buildSettingsRow(
            context: context,
            title: 'Replay Onboarding Tour',
            subtitle: 'Inspect features & toolkit intro',
            icon: Icons.explore_rounded,
            badgeColor: const Color(0xFF8B5CF6), // Purple
            onTap: () => context.push(RouteNames.onboarding),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Permission Explanations',
            subtitle: 'Read Android Scoped Storage policy details',
            icon: Icons.verified_user_rounded,
            badgeColor: const Color(0xFF10B981), // Green
            onTap: () => context.push(
              RouteNames.legalPolicy,
              extra: LegalPolicyType.permissionExplanations,
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Privacy Policy',
            subtitle: 'Zero-data retention & cloud safety',
            icon: Icons.privacy_tip_rounded,
            badgeColor: const Color(0xFFF59E0B), // Amber
            onTap: () => context.push(
              RouteNames.legalPolicy,
              extra: LegalPolicyType.privacyPolicy,
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Terms of Service',
            subtitle: 'User agreements & billing terms',
            icon: Icons.description_rounded,
            badgeColor: const Color(0xFFD97706), // Orange-Amber
            onTap: () => context.push(
              RouteNames.legalPolicy,
              extra: LegalPolicyType.termsOfService,
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Send Feedback & Feature Request',
            subtitle: 'Submit ideas or report issues',
            icon: Icons.rate_review_rounded,
            badgeColor: const Color(0xFF10B981), // Green
            onTap: () => _showFeedbackModal(context),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Help & Support',
            subtitle: 'Contact support@sardarhaseeb.com',
            icon: Icons.help_outline_rounded,
            badgeColor: const Color(0xFFEF4444), // Red
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email: support@sardarhaseeb.com')),
              );
            },
          ),
          _buildSettingsRow(
            context: context,
            title: 'About ScanX AI',
            subtitle: 'v1.0.0 • Developed by Sardar Haseeb',
            icon: Icons.info_rounded,
            badgeColor: const Color(0xFF3B82F6), // Blue
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Open-Source Licenses',
            subtitle: 'Inspect third-party legal attributions',
            icon: Icons.policy_outlined,
            badgeColor: const Color(0xFF64748B), // Slate
            onTap: () => context.push(
              RouteNames.legalPolicy,
              extra: LegalPolicyType.openSourceLicenses,
            ),
          ),
          _buildSettingsRow(
            context: context,
            title: 'Rate App on Google Play',
            subtitle: 'Support ScanX AI with 5 stars ⭐',
            icon: Icons.star_rate_rounded,
            badgeColor: const Color(0xFFF59E0B), // Amber
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for supporting ScanX AI!')),
              );
            },
          ),
          const SizedBox(height: 16),

          // 4. Non-intrusive Banner Ad for free users
          const AdBannerWidget(),
          const SizedBox(height: 16),

          // 5. Footer matching sidebar in image
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3B82F6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SH',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developed by',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'Sardar Haseeb',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Made with ❤️ by Sardar Haseeb\n${AppConstants.copyrightText}\nBundle: ${AppConstants.googlePlayBundleId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  void _showFeedbackModal(BuildContext context) {
    final msgController = TextEditingController();
    String category = 'Feature Request';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.rate_review_rounded, color: Colors.green),
              SizedBox(width: 10),
              Text('Send Feedback'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                    DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                    DropdownMenuItem(value: 'UI / UX Improvement', child: Text('UI / UX Improvement')),
                    DropdownMenuItem(value: 'Other Feedback', child: Text('Other Feedback')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Your Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tell us how we can improve ScanX AI...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = msgController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you! Submitted $category to Sardar Haseeb Technologies.'),
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('About ScanX AI'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The World\'s Best Document Scanner with ML Kit OCR, Pluggable Cloud AI, and Enterprise Keystore Security.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const Divider(height: 28),
              _buildInfoRow('Developer', AppConstants.developerName),
              _buildInfoRow('Company', AppConstants.companyName),
              _buildInfoRow('Website', AppConstants.websiteUrl),
              _buildInfoRow('Support Email', AppConstants.supportEmail),
              const SizedBox(height: 12),
              const Text(
                AppConstants.copyrightText,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, SettingsController controller, String provider) {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configure ${provider.toUpperCase()} Secret Key'),
        content: TextField(
          controller: keyController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Paste API Key (sk-...)',
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
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                controller.setAIProvider(provider, apiKey: key);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${provider.toUpperCase()} Key stored securely in Android Keystore!')),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsController controller) {
    final langs = {
      'en': 'English',
      'es': 'Spanish (Español)',
      'fr': 'French (Français)',
      'de': 'German (Deutsch)',
      'zh': 'Chinese (中文)',
      'ur': 'Urdu (اردو)',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Display Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.entries.map((e) {
            return ListTile(
              title: Text(e.value),
              onTap: () {
                controller.setLanguage(e.key);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
