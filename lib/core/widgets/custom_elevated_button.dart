import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Primary call-to-action button used across the app.
///
/// Defaults to a filled, primary-colored pill with a soft shadow; pass
/// [expanded] to fill available width, or [variant] for subtle alternatives.
class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Widget? leading;
  final bool expanded;
  final bool loading;
  final ButtonVariant variant;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.borderRadius = 12.0,
    this.padding,
    this.width,
    this.height,
    this.leading,
    this.expanded = true,
    this.loading = false,
    this.variant = ButtonVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !loading;
    Color bg = backgroundColor ?? AppColors.primary;
    Color fg = foregroundColor ?? AppColors.white;

    switch (variant) {
      case ButtonVariant.filled:
        break;
      case ButtonVariant.tonal:
        bg = backgroundColor ?? AppColors.primaryTint;
        fg = foregroundColor ?? AppColors.primary;
        break;
      case ButtonVariant.outlined:
        bg = backgroundColor ?? AppColors.surface;
        fg = foregroundColor ?? AppColors.textPrimary;
        break;
    }

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(
                text,
                style:
                    textStyle ?? AppTextStyles.buttonText.copyWith(color: fg),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final side = variant == ButtonVariant.outlined
        ? BorderSide(color: AppColors.border, width: 1)
        : BorderSide.none;

    final elevation = variant == ButtonVariant.filled ? 0.0 : 0.0;

    final inner = Material(
      color: isDisabled ? AppColors.textTertiary.withValues(alpha: 0.5) : bg,
      elevation: elevation,
      shadowColor: AppColors.primary.withValues(alpha: 0.25),
      shape: shape.copyWith(side: side),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: expanded ? double.infinity : width,
          height: height ?? 52,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return SizedBox(width: expanded ? double.infinity : width, child: inner);
  }
}

enum ButtonVariant { filled, tonal, outlined }
