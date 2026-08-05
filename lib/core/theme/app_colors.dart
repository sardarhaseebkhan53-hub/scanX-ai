import 'package:flutter/material.dart';

/// ScanX AI — Ultra-Premium Dark Luxury Design System
/// Deep space navy with neon purple/blue/cyan accents, glassmorphism
class AppColors {
  // ---------- Light (kept for system, but dark is primary) ----------
  static const Color primaryLight = Color(0xFF6D5CFF);
  static const Color secondaryLight = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFF06B6D4);
  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // ---------- Dark Premium Core ----------
  static const Color primaryDark = Color(0xFF7C5CFF); // Electric purple
  static const Color secondaryDark = Color(0xFF5B8DEF); // Neon blue
  static const Color accentDark = Color(0xFF00E5FF); // Cyan neon
  static const Color backgroundDark = Color(0xFF060A18); // Deep space
  static const Color surfaceDark = Color(0xFF0E1330); // Base
  static const Color surfaceDarkElevated = Color(0xFF151D3F); // Elevated card
  static const Color surfaceDarkGlass = Color(0xFF1B244B); // Glass
  static const Color textPrimaryDark = Color(0xFFF0F3FF);
  static const Color textSecondaryDark = Color(0xFF8B94B8);
  static const Color textTertiaryDark = Color(0xFF5A668A);

  // Brand Neon Accents
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonCyan = Color(0xFF06F6FF);
  static const Color neonPink = Color(0xFFEC4899);
  static const Color neonGreen = Color(0xFF10F5A2);
  static const Color neonAmber = Color(0xFFFFC857);

  // Status
  static const Color success = Color(0xFF10F5A2);
  static const Color warning = Color(0xFFFFB86A);
  static const Color error = Color(0xFFFF5A78);
  static const Color info = Color(0xFF5B8DEF);
  static const Color premiumGold = Color(0xFFFFC857);

  // Borders / Glass
  static Color get glassBorder => Colors.white.withOpacity(0.08);
  static Color get glassBorderStrong => Colors.white.withOpacity(0.14);
  static Color get glassFill => Colors.white.withOpacity(0.06);
  static Color get glassFillStrong => Colors.white.withOpacity(0.10);

  // ---------- Premium Gradients ----------
  /// Official brand gradient (magenta -> violet -> blue -> cyan) from the logo.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFD43BF7), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF2FE9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF5B8DEF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF06B6D4), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFFFC857), Color(0xFFFFE08A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF131B3C), Color(0xFF1A2348)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Home dashboard hero mesh
  static const LinearGradient heroMeshGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium banner
  static const LinearGradient premiumBannerGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF3B82F6)],
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
  );

  // Document type accents
  static const List<Color> folderColors = [
    Color(0xFF7C5CFF),
    Color(0xFF10F5A2),
    Color(0xFFA855F7),
    Color(0xFFFFC857),
    Color(0xFFFF5A78),
    Color(0xFFEC4899),
    Color(0xFF06F6FF),
    Color(0xFF64748B),
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

  // Utility: neon glow color for shadows
  static Color neonGlow(Color base, double opacity) => base.withOpacity(opacity);
}
