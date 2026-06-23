import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1E56A0);
  static const Color primaryBlueLight = Color(0xFF3D7DD4);
  static const Color primaryBlueDark = Color(0xFF0D3B7A);

  /// Deep royal blue used by the app icon & splash screen. Drives the
  /// primary brand surfaces (AppBar, buttons, loaders, nav selection).
  static const Color brandBlue = Color(0xFF002C98);

  static const Color secondaryGreen = Color(0xFF2ECC71);
  static const Color secondaryGreenLight = Color(0xFF58D68D);
  static const Color secondaryGreenDark = Color(0xFF1E8449);

  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentRed = Color(0xFFFF6B6B);

  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ---- Soft tints (for card backgrounds / chips) ------------------------
  static const Color blueTint = Color(0xFFEAF1FB);
  static const Color greenTint = Color(0xFFE7F9EF);
  static const Color orangeTint = Color(0xFFFFF3E6);
  static const Color purpleTint = Color(0xFFEFEDFC);
  static const Color redTint = Color(0xFFFFECEC);

  // ---- Brand gradients --------------------------------------------------
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E6FD6), Color(0xFF1E56A0)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B7BF0), Color(0xFF6C5CE7)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF36D77F), Color(0xFF1E8449)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB35C), Color(0xFFFF8C2B)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8C7A), Color(0xFFFF6B6B)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF2E6FD6)],
  );

  /// Blue -> Purple gradient used by the SmartGPT AI Tutor surfaces
  /// (home promo card, floating action button, chat accents).
  static const LinearGradient smartGptGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E6FD6), Color(0xFF8B5CF6)],
  );

  /// Returns a 2-stop gradient derived from a single brand [color].
  static LinearGradient gradientFor(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, Colors.white, 0.18)!,
        color,
      ],
    );
  }

  static Color tintFor(Color color) => color.withValues(alpha: 0.12);
}
