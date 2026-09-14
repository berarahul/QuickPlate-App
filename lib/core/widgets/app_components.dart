import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_provider.dart';

/// Small all-caps label used to introduce sections consistently.
class SectionHeader extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Widget? action;

  const SectionHeader({super.key, required this.text, this.style, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: style ?? AppTextStyles.labelSmall),
        ?action,
      ],
    );
  }
}

/// Centered placeholder for empty / loading / error states.
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBg;

  const StateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    final effectiveIconBg = iconBg ?? AppColors.primaryTint;
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveTitleColor = AppColors.textPrimary;
    final effectiveMessageColor = AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 40,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: effectiveTitleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: effectiveMessageColor,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryTint,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
