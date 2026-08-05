import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  int _selectedPlanIndex = 1;
  int _countdownSeconds = 86400;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _countdownSeconds > 0) setState(() => _countdownSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar(
        title: 'ScanX Pro',
        subtitle: 'Unlock Intelligence',
        leading: GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))),
        showBackButton: false,
      ),
      body: Stack(
        children: [
          Positioned(top: -120, left: -80, child: Container(width: 380, height: 380, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.22), Colors.transparent])))),
          Positioned(bottom: -60, right: -60, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonBlue.withOpacity(0.18), Colors.transparent])))),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF5A78), Color(0xFFF97316)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.35), blurRadius: 16)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.timer_outlined, color: Colors.white, size: 16), const SizedBox(width: 6), Text('OFFER ENDS IN ${_fmt(_countdownSeconds)}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6))]),
                ),
                const SizedBox(height: 22),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.goldGradient.colors.first.withOpacity(0.25), Colors.transparent]))),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.goldGradient.colors.first.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))]),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 44),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Unlock Total\nDocument Intelligence', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8)),
                const SizedBox(height: 12),
                Text('Supercharge with unlimited AI OCR, cloud sync, AES-256 vault and zero ads.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 24),
                ...[
                  'Unlimited AI Chat, Summary, Translation',
                  'Zero Ads across entire app',
                  'AES-256 Hidden Vault + Biometrics',
                  'Multi-cloud sync • Drive, Dropbox',
                  'All 12 PDF tools + Batch processing',
                  'Priority VIP support',
                ].map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Container(width: 22, height: 22, decoration: BoxDecoration(gradient: AppColors.emeraldGradient, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 14)), const SizedBox(width: 10), Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)))]))),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: _PricingCard(index: 0, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Monthly', price: '\$4.99/mo', sub: 'Billed monthly')),
                  const SizedBox(width: 10),
                  Expanded(child: _PricingCard(index: 1, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Yearly', price: '\$29.99/yr', sub: 'Save 50%', badge: 'POPULAR')),
                  const SizedBox(width: 10),
                  Expanded(child: _PricingCard(index: 2, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Lifetime', price: '\$79.99', sub: 'One-time')),
                ]),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Google Play Billing...'), backgroundColor: Color(0xFF151D3F))),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))], border: Border.all(color: Colors.white.withOpacity(0.14))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bolt_rounded, color: Colors.white, size: 20), SizedBox(width: 8), Text('Start 7-Day Free Trial', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: () {}, child: Text('Restore', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12))), Text('•', style: TextStyle(color: AppColors.textSecondaryDark)), TextButton(onPressed: () {}, child: Text('Cancel Anytime', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final int index, selected;
  final Function(int) onTap;
  final String title, price, sub;
  final String? badge;
  const _PricingCard({required this.index, required this.selected, required this.onTap, required this.title, required this.price, required this.sub, this.badge});

  @override
  Widget build(BuildContext context) {
    final isSel = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSel ? const LinearGradient(colors: [Color(0xFF1E2750), Color(0xFF1A2348)]) : const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF111936)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSel ? AppColors.primaryDark.withOpacity(0.6) : Colors.white.withOpacity(0.07), width: isSel ? 1.6 : 1),
          boxShadow: isSel ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.25), blurRadius: 18)] : null,
        ),
        child: Column(children: [
          if (badge != null) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(10)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6))),
          Text(title, style: TextStyle(color: isSel ? Colors.white : AppColors.textSecondaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          Text(price, textAlign: TextAlign.center, style: TextStyle(color: isSel ? Colors.white : AppColors.textSecondaryDark, fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 10, color: isSel ? AppColors.neonGreen : AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
