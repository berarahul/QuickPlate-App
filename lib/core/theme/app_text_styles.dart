import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Minimal, professional type system built on a single geometric family.
///
/// To self-host a custom font later, add it under `flutter.fonts` in
/// pubspec.yaml and replace [fontFamily] below.
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Splash ───────────────────────────────────────────────────
  static const TextStyle splashTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Headings ───────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ───────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  // ── Label / Button ─────────────────────────────────────────────────────
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.1,
  );

  static const TextStyle textButton = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.6,
    height: 1.4,
  );
}
