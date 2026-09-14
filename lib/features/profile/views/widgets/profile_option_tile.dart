import '../../../../core/app_exports.dart';

class ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBg;
  final Widget? trailing;

  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBg,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBg = iconBg ?? AppColors.primaryTint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: effectiveIconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),
          title: Text(title, style: AppTextStyles.titleSmall),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
          trailing:
              trailing ??
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
