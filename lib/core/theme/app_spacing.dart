import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing Scale (4dp grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Border Radiuses
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 100.0;

  // EdgeInsets helpers
  static const EdgeInsets padAllSm = EdgeInsets.all(sm);
  static const EdgeInsets padAllMd = EdgeInsets.all(md);
  static const EdgeInsets padAllLg = EdgeInsets.all(lg);
  static const EdgeInsets padAllXl = EdgeInsets.all(xl);
  static const EdgeInsets padAllXxl = EdgeInsets.all(xxl);

  static const EdgeInsets padHorizLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets padHorizXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets padHorizXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Soft Premium Shadows
  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glowShadowBlue => [
        BoxShadow(
          color: const Color(0xFF2563EB).withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glowShadowPurple => [
        BoxShadow(
          color: const Color(0xFF8B5CF6).withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glowShadowGold => [
        BoxShadow(
          color: const Color(0xFFF59E0B).withOpacity(0.38),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
