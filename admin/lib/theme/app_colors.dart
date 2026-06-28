import 'package:flutter/material.dart';

/// Central color palette — shared, identical to the Aarvy patient app so the
/// hospital-side apps stay visually consistent.
///
/// A calm, trustworthy, clinical-yet-warm green & white medical theme.
class AppColors {
  AppColors._();

  // ---- Brand greens ----
  static const Color primary = Color(0xFF2E7D5B); // deep medical green
  static const Color primaryDark = Color(0xFF1F5C42);
  static const Color primaryBright = Color(0xFF34A853); // accent green
  static const Color primaryLight = Color(0xFF5CC08A);

  // ---- Mint / soft accents ----
  static const Color mint = Color(0xFFE8F5E9);
  static const Color mintDark = Color(0xFFD4ECD8);
  static const Color softGreenTint = Color(0xFFF1F9F3);

  // ---- Neutrals ----
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF7FAF8); // very soft off-white green
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAEFEC);
  static const Color divider = Color(0xFFEEF2EF);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5B6B63);
  static const Color textTertiary = Color(0xFF93A199);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---- Status / semantic ----
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);
  static const Color star = Color(0xFFFFB400);

  // ---- Specialty accent palette (for chips / category icons) ----
  static const Color accentBlue = Color(0xFF4A90D9);
  static const Color accentPurple = Color(0xFF8B6FD8);
  static const Color accentPink = Color(0xFFE57399);
  static const Color accentOrange = Color(0xFFF0883E);
  static const Color accentTeal = Color(0xFF2BB3A3);
  static const Color accentRed = Color(0xFFE5615F);

  // ---- Glassmorphism ----
  static const Color glassWhite = Color(0x80FFFFFF); // 50% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassDark = Color(0x26000000); // 15% black
  static const Color glassGreen = Color(0x1A2E7D5B); // 10% primary

  // ---- Shimmer / pulse ----
  static const Color shimmerBase = Color(0xFFE8F5E9);
  static const Color shimmerHighlight = Color(0xFFF1F9F3);

  // ---- Hover / press ----
  static const Color hoverOverlay = Color(0x0A2E7D5B); // 4% primary
  static const Color pressOverlay = Color(0x142E7D5B); // 8% primary

  // ---- Gradients ----
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34A853), Color(0xFF2E7D5B)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D5B), Color(0xFF1F5C42)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF1F9F3), Color(0xFFFFFFFF)],
  );

  /// Rich multi-stop gradient for login backgrounds.
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F5C42),
      Color(0xFF2E7D5B),
      Color(0xFF34A853),
      Color(0xFF2E7D5B),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  /// Subtle card glow: used behind stat cards for depth.
  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0834A853), Color(0x002E7D5B)],
  );

  /// Deep dark gradient for terminal/log panels.
  static const LinearGradient terminalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1F16), Color(0xFF132B1E)],
  );

  // ---- Shadows ----
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF2E7D5B).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF2E7D5B).withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Hover glow for interactive cards.
  static List<BoxShadow> get hoverGlow => [
        BoxShadow(
          color: const Color(0xFF2E7D5B).withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: const Color(0xFF34A853).withValues(alpha: 0.06),
          blurRadius: 40,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];
}
