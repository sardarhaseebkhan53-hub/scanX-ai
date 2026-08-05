import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - Premium Royal Blue, Purple, Cyan
  static const Color primaryLight = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryLight = Color(0xFF7C3AED); // Purple
  static const Color accentLight = Color(0xFF0891B2); // Cyan
  static const Color backgroundLight = Color(0xFFF8FAFC); // Very light gray
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Mode Palette - Deep Obsidian Black & Glowing Cyber Blue
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF8B5CF6);
  static const Color accentDark = Color(0xFF06B6D4);
  static const Color backgroundDark = Color(0xFF020617); // Deep space navy
  static const Color surfaceDark = Color(0xFF0F172A); // Elevated surface
  static const Color surfaceDarkElevated = Color(0xFF111827); // Card surface
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status & Alerts (Success, Warning, Error)
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF97316); // Vibrant Orange
  static const Color error = Color(0xFFEF4444); // Crimson Red
  static const Color info = Color(0xFF3B82F6);
  static const Color premiumGold = Color(0xFFF59E0B);

  // Luxurious Linear Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF14141A), Color(0xFF1E1E26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Folder & Category Tag Colors
  static const List<Color> folderColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF64748B), // Slate
  ];

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
