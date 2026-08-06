import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/monetization/billing_service.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../controllers/settings_controller.dart';
import 'legal_policy_screen.dart';

/// Profile tab — account surface with premium status, personal stats,
/// theme control and shortcuts to every settings & compliance surface.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);
    final homeState = ref.watch(homeProvider);
    final billing = sl<BillingService>();

    final favs = homeState.documents.where((d) => d.isFavorite).length;
    final locked = homeState.documents.where((d) => d.isLocked).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 160 + MediaQuery.of(context).padding.bottom),
          children: [
            Center(
              child: Column(
                children: [
                  const ScanXLogoIcon(size: 84),
                  const SizedBox(height: 14),
                  const ScanXWordmark(fontSize: 24),
                  const SizedBox(height: 6),
                  Text('v${AppConstants.appVersion} • ${AppConstants.companyName}', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<bool>(
              stream: billing.premiumStatusStream,
              initialData: billing.isPremium,
              builder: (context, snap) {
                final isPremium = snap.data ?? false;
                if (isPremium) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3A2B00), Color(0xFF241A00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFC857).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const PremiumCrownIcon(size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ScanX Pro Active', style: TextStyle(color: Color(0xFFFFC857), fontSize: 15, fontWeight: FontWeight.w900)),
                              Text('Unlimited scans, AI & 100GB cloud storage', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: Color(0xFFFFC857), size: 22),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(1.4),
                  decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF0D0A1E), borderRadius: BorderRadius.circular(18.8)),
                    child: Row(
                      children: [
                        const PremiumCrownIcon(size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Go Premium. Do More.', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                              Text('Unlimited AI, cloud storage & ad-free', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(RouteNames.premiumPaywall),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                            child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                children: [
                  _StatCard(value: '${homeState.documents.length}', label: 'Documents', icon: Icons.description_rounded, color: AppColors.neonBlue),
                  const SizedBox(width: 10),
                  _StatCard(value: '$favs', label: 'Favorites', icon: Icons.favorite_rounded, color: AppColors.neonPink),
                  const SizedBox(width: 10),
                  _StatCard(value: '$locked', label: 'In Vault', icon: Icons.lock_rounded, color: AppColors.neonPurple),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('PREFERENCES', style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF10152B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Row(
                children: [
                  Icon(Icons.palette_rounded, color: AppColors.neonCyan, size: 20),
                  const SizedBox(width: 12),
                  const Text('Appearance', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  ...['light', 'dark', 'system'].map((m) {
                    final sel = settings.themeMode == m;
                    return GestureDetector(
                      onTap: () => settingsController.setThemeMode(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.brandGradient : null,
                          color: sel ? null : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m[0].toUpperCase() + m.substring(1), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('MANAGE', style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _ProfileTile(icon: Icons.settings_rounded, color: AppColors.neonBlue, title: 'Settings', subtitle: 'AI engine, scanning, PDF quality', onTap: () => context.push(RouteNames.settings)),
            _ProfileTile(icon: Icons.shield_rounded, color: AppColors.neonPurple, title: 'Security & Vault', subtitle: 'PIN, pattern, biometrics, auto-lock', onTap: () => context.push(RouteNames.securitySettings)),
            _ProfileTile(icon: Icons.cloud_sync_rounded, color: AppColors.neonCyan, title: 'Cloud Sync & Backup', subtitle: 'Firebase sync, Drive, Dropbox, OneDrive', onTap: () => context.push(RouteNames.cloudSync)),
            _ProfileTile(icon: Icons.qr_code_2_rounded, color: AppColors.neonGreen, title: 'QR & Wi-Fi Toolkit', subtitle: 'Scan history, generators, Wi-Fi studio', onTap: () => context.push(RouteNames.qrDashboard)),
            _ProfileTile(icon: Icons.picture_as_pdf_rounded, color: AppColors.neonPink, title: 'PDF Toolkit', subtitle: '16 professional PDF tools', onTap: () => context.push(RouteNames.pdfTools)),
            _ProfileTile(icon: Icons.policy_rounded, color: AppColors.neonAmber, title: 'Legal & Compliance', subtitle: 'Privacy, terms, permissions, licenses', onTap: () => context.push(RouteNames.legalPolicy, extra: LegalPolicyType.privacyPolicy)),
            _ProfileTile(
              icon: Icons.restore_rounded,
              color: AppColors.textSecondaryDark,
              title: 'Restore Purchases',
              subtitle: 'Re-activate previous Pro purchases',
              onTap: () async {
                await billing.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase restore completed'), backgroundColor: Color(0xFF151D3F)));
                }
              },
            ),
            const SizedBox(height: 22),
            Text(
              '${AppConstants.developerName}\n${AppConstants.copyrightText}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10.5, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF10152B), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: const Color(0xFF10152B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
