import 'package:flutter/material.dart';

/// Centralized, minimal & professional color palette.
/// Support for light and dark theme mode.
class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // ── Brand ──────────────────────────────────────────────────────────────
  static Color get primary => const Color(0xFFE85D2F);
  static Color get primaryDark => const Color(0xFFC84518);
  static Color get primaryLight => isDarkMode ? const Color(0xFF5E2711) : const Color(0xFFFBD4C2);
  static Color get primaryTint => isDarkMode ? const Color(0xFF2C1309) : const Color(0xFFFDF1EB);

  // ── Surfaces / Neutrals ───────────────────────────────────────────────
  static Color get background => isDarkMode ? const Color(0xFF0C0A09) : const Color(0xFFFAF9F7);
  static Color get surface => isDarkMode ? const Color(0xFF1C1917) : Colors.white;
  static Color get surfaceAlt => isDarkMode ? const Color(0xFF292524) : const Color(0xFFF3F2EF);

  // ── Text ───────────────────────────────────────────────────────────────
  static Color get textPrimary => isDarkMode ? const Color(0xFFF5F5F4) : const Color(0xFF1F1B16);
  static Color get textSecondary => isDarkMode ? const Color(0xFFA8A29E) : const Color(0xFF6B655E);
  static Color get textTertiary => isDarkMode ? const Color(0xFF78716C) : const Color(0xFFA39E97);

  // ── Lines ──────────────────────────────────────────────────────────────
  static Color get border => isDarkMode ? const Color(0xFF292524) : const Color(0xFFE8E5E0);
  static Color get divider => isDarkMode ? const Color(0xFF1C1917) : const Color(0xFFF0EEE9);

  // ── Semantic ───────────────────────────────────────────────────────────
  static Color get success => const Color(0xFF16A34A);
  static Color get successTint => isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFE9F7EE);
  static Color get error => const Color(0xFFDC2626);
  static Color get errorTint => isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFDECEC);
  static Color get warning => const Color(0xFFD97706);
  static Color get warningTint => isDarkMode ? const Color(0xFF78350F) : const Color(0xFFFBF1E4);
  static Color get info => const Color(0xFF2563EB);
  static Color get infoTint => isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFFEAF1FE);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color overlay = Color(0x0D000000);
}
