import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/monetization/billing_service.dart';
import '../../../../shared/widgets/brand_logo.dart';

/// "Go Premium. Do More." — ScanX Pro paywall with real Google Play Billing:
/// monthly / annual / lifetime plans, restore purchases and live premium state.
class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  int _selectedPlanIndex = 1;
  bool _busy = false;
  StreamSubscription<bool>? _premiumSub;

  static const List<String> _planIds = [
    AppConstants.monthlySubscriptionId,
    AppConstants.annualSubscriptionId,
    AppConstants.lifetimePurchaseId,
  ];

  @override
  void initState() {
    super.initState();
    _premiumSub = sl<BillingService>().premiumStatusStream.listen((premium) {
      if (premium && mounted) {
        _showWelcomeDialog();
      }
    });
  }

  @override
  void dispose() {
    _premiumSub?.cancel();
    super.dispose();
  }

  void _showWelcomeDialog() {
    setState(() => _busy = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), side: BorderSide(color: AppColors.premiumGold.withOpacity(0.5))),
        title: const Row(children: [PremiumCrownIcon(size: 30), SizedBox(width: 10), Text('Welcome to Pro!', style: TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.w900))]),
        content: Text('Unlimited scans, unlimited AI, 100GB cloud storage and an ad-free experience are now active.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue', style: TextStyle(color: AppColors.premiumGold, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    final billing = sl<BillingService>();
    setState(() => _busy = true);

    final id = _planIds[_selectedPlanIndex];
    ProductDetails? product;
    for (final p in billing.availableProducts) {
      if (p.id == id) product = p;
    }

    if (product == null) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Play store is unavailable on this device. Try again on a device with Play Services.'), backgroundColor: Color(0xFF3A1220)),
        );
      }
      return;
    }

    final started = await billing.buyProduct(product);
    if (mounted) {
      setState(() => _busy = false);
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase could not be started.'), backgroundColor: Color(0xFF3A1220)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned(top: -120, left: -80, child: Container(width: 380, height: 380, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.22), Colors.transparent])))),
          Positioned(bottom: -60, right: -60, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonBlue.withOpacity(0.18), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)),
                      ),
                      const Spacer(),
                      const ScanXWordmark(fontSize: 16),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.premiumGold.withOpacity(0.28), Colors.transparent]))),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.premiumGold.withOpacity(0.45), blurRadius: 26, offset: const Offset(0, 8))]),
                              child: const PremiumCrownIcon(size: 46),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Go Premium. ', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                            TextSpan(text: 'Do More.', style: TextStyle(color: AppColors.neonPurple, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                          ]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text('Unlock the full power of ScanX AI and experience next-level productivity.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 22),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3.4),
                          children: const [
                            _Benefit(label: 'Unlimited Scans'),
                            _Benefit(label: 'AI Summaries (Unlimited)'),
                            _Benefit(label: 'AI Chat (Unlimited)'),
                            _Benefit(label: 'Advanced PDF Tools'),
                            _Benefit(label: 'Cloud Storage (100GB)'),
                            _Benefit(label: 'Batch Processing'),
                            _Benefit(label: 'Ad-Free Experience'),
                            _Benefit(label: 'Priority Support'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(children: [
                          _PricingCard(index: 0, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Monthly', price: '\$4.99/mo', sub: 'Billed monthly'),
                          const SizedBox(width: 10),
                          _PricingCard(index: 1, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Yearly', price: '\$29.99/yr', sub: 'Save 50%', badge: 'POPULAR'),
                          const SizedBox(width: 10),
                          _PricingCard(index: 2, selected: _selectedPlanIndex, onTap: (i) => setState(() => _selectedPlanIndex = i), title: 'Lifetime', price: '\$79.99', sub: 'One-time'),
                        ]),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _busy ? null : _purchase,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))],
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
                            ),
                            child: _busy
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    PremiumCrownIcon(size: 22),
                                    SizedBox(width: 10),
                                    Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                  ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          TextButton(
                            onPressed: () async {
                              await sl<BillingService>().restorePurchases();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore completed'), backgroundColor: Color(0xFF151D3F)));
                            },
                            child: Text('Restore Purchases', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                          ),
                          Text('•', style: TextStyle(color: AppColors.textSecondaryDark)),
                          TextButton(onPressed: () => Navigator.pop(context), child: Text('Maybe Later', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12))),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String label;
  const _Benefit({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(gradient: AppColors.emeraldGradient, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2))),
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
