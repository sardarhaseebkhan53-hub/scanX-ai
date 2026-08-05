import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Professional AI Scanner',
      'subtitle': 'CameraX-Quality • 8 Scan Modes • Auto-Edge Detection',
      'description':
          'Capture documents, receipts, ID cards, and books with intelligent edge tracking, blur detection, and instant shadow & reflection removal.',
      'icon': Icons.camera_enhance_rounded,
      'color': const Color(0xFF3B82F6), // Royal Blue
    },
    {
      'title': 'QR & Wi-Fi Toolkit + OCR',
      'subtitle': 'Live Barcode Reader • WPA/WPA3 Creator • Google ML Kit',
      'description':
          'Scan and generate Wi-Fi, URL, and vCard QR codes safely. Extract selectable text from any document with 98% accuracy across 8 languages.',
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xFF10B981), // Emerald Green
    },
    {
      'title': 'AES-256 Vault & Cloud Sync',
      'subtitle': 'Keystore Shield • Hidden Vault • Firebase Bi-Directional Sync',
      'description':
          'Protect private documents with fingerprint, Face ID, PIN, or 3x3 pattern lock. Sync seamlessly across Firebase, Google Drive, and Dropbox.',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF8B5CF6), // Purple AI
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.workspace_premium_rounded,
                            color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // 2. PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPageIndex = idx),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final Color slideColor = slide['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: slideColor.withOpacity(0.14),
                            shape: BoxShape.circle,
                            border: Border.all(color: slideColor.withOpacity(0.35), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: slideColor.withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 84,
                            color: slideColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: slideColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Page Indicators & Next/Start Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSelected = _currentPageIndex == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (_currentPageIndex < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    icon: Icon(
                      _currentPageIndex < _slides.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentPageIndex < _slides.length - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
