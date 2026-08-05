import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Settings', subtitle: 'Premium • Secure • Private'),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.primaryDark.withOpacity(0.12), Colors.transparent])))),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Profile premium header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF111936)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: AppSpacing.cardShadowDark,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.scannerGradient),
                      child: const CircleAvatar(radius: 24, backgroundColor: Color(0xFF151D3F), child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Haseeb Ahmed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Pro Member • Cloud Synced', style: TextStyle(color: Color(0xFF8B94B8), fontSize: 12)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Text('PRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel(title: 'General', icon: Icons.tune_rounded),
              _LuxRow(title: 'Appearance', subtitle: 'Dark Mode • ${state.themeMode.toUpperCase()}', icon: Icons.palette_rounded, gradient: AppColors.goldGradient, trailing: DropdownButton<String>(value: state.themeMode, underline: const SizedBox(), dropdownColor: const Color(0xFF151D3F), style: const TextStyle(color: Colors.white, fontSize: 13), items: const [DropdownMenuItem(value: 'system', child: Text('System')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))], onChanged: (v) { if (v != null) controller.setThemeMode(v); })),
              _LuxRow(title: 'Language', subtitle: 'English (${state.languageCode.toUpperCase()})', icon: Icons.language_rounded, gradient: AppColors.scannerGradient, onTap: () => _showLanguagePicker(context, controller)),
              _LuxRow(title: 'Cloud Backup & Sync', subtitle: 'Firebase • Drive • Dropbox', icon: Icons.cloud_done_rounded, gradient: AppColors.cyanGradient, onTap: () => context.push(RouteNames.cloudSync)),
              _LuxRow(title: 'Security & Privacy', subtitle: 'AES-256 • Biometrics', icon: Icons.security_rounded, gradient: AppColors.purpleGradient, onTap: () => context.push(RouteNames.securitySettings)),

              const SizedBox(height: 16),
              _SectionLabel(title: 'AI & Scanner', icon: Icons.auto_awesome_rounded),
              _LuxRow(title: 'AI Engine', subtitle: 'Provider: ${state.aiProvider.toUpperCase()}', icon: Icons.smart_toy_rounded, gradient: AppColors.aiGradient, onTap: () => _showApiKeyDialog(context, controller, state.aiProvider)),
              _LuxRow(title: 'Watermark Studio', subtitle: state.defaultWatermarkConfig.isEnabled ? 'Active • ${state.defaultWatermarkConfig.position}' : 'Disabled', icon: Icons.water_drop_rounded, gradient: AppColors.cyanGradient, onTap: () {
                WatermarkStudioModal.show(context, initialConfig: state.defaultWatermarkConfig, onApply: (config) { controller.updateWatermarkConfig(config); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watermark updated!'), backgroundColor: Color(0xFF151D3F))); });
              }),
              _LuxRow(title: 'Auto Edge Detection', subtitle: state.autoEdgeDetection ? 'AI Powered • ON' : 'OFF', icon: Icons.crop_free_rounded, gradient: AppColors.primaryGradient, trailing: Switch(value: state.autoEdgeDetection, activeColor: AppColors.primaryDark, onChanged: (v) => controller.toggleAutoEdge(v))),

              const SizedBox(height: 16),
              _SectionLabel(title: 'Support & Legal', icon: Icons.help_center_rounded),
              _LuxRow(title: 'Onboarding Tour', subtitle: 'Explore features', icon: Icons.explore_rounded, gradient: AppColors.purpleGradient, onTap: () => context.push(RouteNames.onboarding)),
              _LuxRow(title: 'Privacy Policy', subtitle: 'Zero-data retention', icon: Icons.privacy_tip_rounded, gradient: AppColors.goldGradient, onTap: () => context.push(RouteNames.legalPolicy, extra: LegalPolicyType.privacyPolicy)),
              _LuxRow(title: 'Terms of Service', subtitle: 'Billing & agreements', icon: Icons.description_rounded, gradient: AppColors.emeraldGradient, onTap: () => context.push(RouteNames.legalPolicy, extra: LegalPolicyType.termsOfService)),
              _LuxRow(title: 'Send Feedback', subtitle: 'Feature request & bugs', icon: Icons.rate_review_rounded, gradient: AppColors.cyanGradient, onTap: () => _showFeedbackModal(context)),
              _LuxRow(title: 'Rate & Review', subtitle: '5 stars on Google Play', icon: Icons.star_rate_rounded, gradient: AppColors.goldGradient, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for supporting ScanX AI!'), backgroundColor: Color(0xFF151D3F)))),

              const SizedBox(height: 24),
              // Footer dev card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF121A36), Color(0xFF151D3F)]),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.scannerGradient, shape: BoxShape.circle), child: const Center(child: Text('SH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Developed by', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)), Text('Sardar Haseeb', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))]),
                    ]),
                    const SizedBox(height: 12),
                    Text('Made with ❤️ • ${AppConstants.copyrightText}\n${AppConstants.googlePlayBundleId}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showLanguagePicker(BuildContext context, SettingsController controller) {
    final langs = {'en': 'English', 'es': 'Español', 'fr': 'Français', 'de': 'Deutsch', 'ur': 'Urdu'};
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))), builder: (ctx) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: langs.entries.map((e) => ListTile(title: Text(e.value, style: const TextStyle(color: Colors.white)), onTap: () { controller.setLanguage(e.key); Navigator.pop(ctx); })).toList())));
  }

  static void _showApiKeyDialog(BuildContext context, SettingsController controller, String provider) {
    final keyController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.08))), title: Text('Configure ${provider.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), content: TextField(controller: keyController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Paste API Key', hintStyle: TextStyle(color: AppColors.textSecondaryDark), filled: true, fillColor: const Color(0xFF101735), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))), Container(decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(10)), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: () { final key = keyController.text.trim(); if (key.isNotEmpty) { controller.setAIProvider(provider, apiKey: key); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${provider.toUpperCase()} key secured!'), backgroundColor: const Color(0xFF151D3F))); } }, child: const Text('Save', style: TextStyle(color: Colors.white))))]));
  }

  static void _showFeedbackModal(BuildContext context) {
    final msgController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Send Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), content: TextField(controller: msgController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Tell us how to improve...', hintStyle: TextStyle(color: AppColors.textSecondaryDark), filled: true, fillColor: const Color(0xFF101735), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), Container(decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(10)), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you! Feedback submitted.'), backgroundColor: Color(0xFF151D3F))); }, child: const Text('Submit', style: TextStyle(color: Colors.white))))]));
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(children: [
        Container(width: 26, height: 26, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: Colors.white, size: 14)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: -0.2)),
      ]),
    );
  }
}

class _LuxRow extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _LuxRow({required this.title, required this.subtitle, required this.icon, required this.gradient, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(11), boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(icon, color: Colors.white, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark)),
        trailing: trailing ?? Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08))), child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white54)),
        onTap: onTap,
      ),
    );
  }
}
