import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A unified surface container used for list items, info panels and stats.
/// Bordered, soft-shadowed and rounded — the single "card" style app-wide.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 16,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: AppColors.border, width: 1),
      boxShadow: const [
        BoxShadow(
          color: AppColors.overlay,
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );

    final content = Container(
      margin: margin,
      decoration: decoration,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
