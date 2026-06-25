import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Minimal, professional type system built on a single geometric family.
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Splash ───────────────────────────────────────────────────
  static TextStyle get splashTitle => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ── Headings ───────────────────────────────────────────────────────────
  static TextStyle get displayLarge => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get titleSmall => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Body ───────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ── Label / Button ─────────────────────────────────────────────────────
  static TextStyle get buttonText => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.1,
      );

  static TextStyle get textButton => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.6,
        height: 1.4,
      );
}
