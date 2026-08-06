import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Premium 3-slide brand tour: Lightning-Fast AI Scanning, AI Intelligence,
/// Enterprise Security & Offline — mirrors the product value proposition.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned(top: -140, left: -100, child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.20), Colors.transparent])))),
          Positioned(bottom: -120, right: -100, child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonCyan.withOpacity(0.14), Colors.transparent])))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 8),
                  child: Row(
                    children: [
                      const ScanXLogoIcon(size: 30),
                      const SizedBox(width: 8),
                      const ScanXWordmark(fontSize: 17),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text('Skip', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: const [
                      _Slide(
                        icon: Icons.document_scanner_rounded,
                        gradient: AppColors.scannerGradient,
                        title: 'Lightning Fast\nAI Scanning',
                        subtitle: 'Auto edge detection, perspective correction and 99% OCR accuracy — scan documents, receipts, books, IDs & whiteboards in seconds.',
                        chips: ['Auto Edge Detection', '99% OCR Accuracy', '14 Pro Filters'],
                      ),
                      _Slide(
                        icon: Icons.auto_awesome_rounded,
                        gradient: AppColors.aiGradient,
                        title: 'AI That\nUnderstands',
                        subtitle: 'Instant summaries, chat with your documents, rewrite text, parse receipts and translate into 8+ languages — powered by Gemini & GPT-4o.',
                        chips: ['AI Summaries', 'Chat with Docs', 'Receipt AI'],
                      ),
                      _Slide(
                        icon: Icons.shield_rounded,
                        gradient: AppColors.cyanGradient,
                        title: 'Enterprise Security.\nAnywhere.',
                        subtitle: 'AES-256 encrypted vault with biometrics, PIN & pattern lock. 100% offline support with optional cloud backup & sync across devices.',
                        chips: ['AES-256 Vault', 'Offline Mode', 'Cloud Sync'],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final sel = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: sel ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.brandGradient : null,
                        color: sel ? null : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_page < 2) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                      } else {
                        _finish();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))],
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_page < 2 ? 'Continue' : 'Get Started', style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(colors: const [Color(0xFFD43BF7), Color(0xFF8B5CF6), Color(0xFF38D5F7)]).createShader(rect),
                    child: const Text('SMART SCANNER. SMARTER AI.', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
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

class _Slide extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final List<String> chips;
  const _Slide({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.chips});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the hero circle down on short/small screens to prevent the
        // "RenderFlex overflowed on the bottom" layout assertion.
        final heroSize = (constraints.maxHeight * 0.32).clamp(120.0, 150.0);
        final glowSize = heroSize * 1.4;
        final iconSize = heroSize * 0.43;
        final titleSize = (constraints.maxHeight < 520) ? 25.0 : 30.0;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: glowSize, height: glowSize, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [gradient.colors.first.withOpacity(0.28), Colors.transparent]))),
                      Container(
                        width: heroSize,
                        height: heroSize,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.5), blurRadius: 34, offset: const Offset(0, 12))],
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                    ],
                  ),
                  SizedBox(height: (constraints.maxHeight * 0.06).clamp(16.0, 40.0)),
                  Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w900, height: 1.12, letterSpacing: -0.8)),
                  const SizedBox(height: 16),
                  Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5, height: 1.6)),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: gradient.colors.first.withOpacity(0.4)),
                              ),
                              child: Text(c, style: TextStyle(color: gradient.colors.first, fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
