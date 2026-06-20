import 'package:flutter/material.dart';

/// Centralized, minimal & professional color palette.
///
/// Design principles:
/// - One warm brand color (refined terracotta-orange), not harsh `Colors.orange`.
/// - A cohesive warm-neutral gray scale for surfaces, text & borders.
/// - Subtle tints for accents instead of saturated fills.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  /// Primary brand color — warm, slightly desaturated orange.
  static const Color primary = Color(0xFFE85D2F);
  static const Color primaryDark = Color(0xFFC84518);
  static const Color primaryLight = Color(0xFFFBD4C2);

  /// Very soft tint used for chip backgrounds, highlights & avatars.
  static const Color primaryTint = Color(0xFFFDF1EB);

  // ── Surfaces / Neutrals (warm gray) ────────────────────────────────────
  static const Color background = Color(0xFFFAF9F7);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF3F2EF);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F1B16);
  static const Color textSecondary = Color(0xFF6B655E);
  static const Color textTertiary = Color(0xFFA39E97);

  // ── Lines ──────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE8E5E0);
  static const Color divider = Color(0xFFF0EEE9);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successTint = Color(0xFFE9F7EE);
  static const Color error = Color(0xFFDC2626);
  static const Color errorTint = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFD97706);
  static const Color warningTint = Color(0xFFFBF1E4);
  static const Color info = Color(0xFF2563EB);
  static const Color infoTint = Color(0xFFEAF1FE);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color overlay = Color(0x0D000000);
}
