import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing Scale (4dp grid premium)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // Border Radiuses — rounder, luxury
  static const double radiusXs = 10.0;
  static const double radiusSm = 14.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 22.0;
  static const double radiusXl = 28.0;
  static const double radiusXxl = 32.0;
  static const double radiusPill = 999.0;

  // EdgeInsets helpers
  static const EdgeInsets padAllSm = EdgeInsets.all(sm);
  static const EdgeInsets padAllMd = EdgeInsets.all(md);
  static const EdgeInsets padAllLg = EdgeInsets.all(lg);
  static const EdgeInsets padAllXl = EdgeInsets.all(xl);
  static const EdgeInsets padAllXxl = EdgeInsets.all(xxl);

  static const EdgeInsets padHorizLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets padHorizXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets padHorizXxl = EdgeInsets.symmetric(horizontal: xxl);

  // ---------- Luxury Shadows ----------
  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.40),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadowBlue => [
        BoxShadow(
          color: const Color(0xFF7C5CFF).withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF3B82F6).withOpacity(0.25),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get glowShadowPurple => [
        BoxShadow(
          color: const Color(0xFFA855F7).withOpacity(0.40),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF7C3AED).withOpacity(0.25),
          blurRadius: 50,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get glowShadowCyan => [
        BoxShadow(
          color: const Color(0xFF06B6D4).withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadowGold => [
        BoxShadow(
          color: const Color(0xFFFFC857).withOpacity(0.38),
          blurRadius: 26,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}
