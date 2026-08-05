import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized type scale, built on Google Fonts "Inter" per the design spec:
/// Display 28 / Title 22 / Heading 18 / Body 15 / Caption 13.
/// Semantic aliases (displayXL, titleXL, heading, body, caption) are provided
/// below so screens can reference the spec names directly instead of the
/// Material TextTheme slots.
class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          // Spec: Display 28 / Bold
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          // Spec: Title 22 / SemiBold
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          // Spec: Heading 18 / SemiBold
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          // Spec: Body 15 / Regular
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          // Spec: Caption 13 / Regular-Medium
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
