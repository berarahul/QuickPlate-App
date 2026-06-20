import 'package:provider/provider.dart';
import '../../../core/app_exports.dart';
import '../../notifications/provider/notification_provider.dart';
import '../../auth/provider/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out from QuickPlate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (overlayContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              await context.read<AuthProvider>().logout();

              if (context.mounted) {
                Navigator.pop(context); // Close loading overlay
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account', style: AppTextStyles.labelSmall),
              const SizedBox(height: 4),
              Text('Profile', style: AppTextStyles.displayLarge),
              const SizedBox(height: 24),
              // Profile header card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 34, color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Name', style: AppTextStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text('student@email.com',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('ACTIVITY', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              _buildProfileOption(
                icon: Icons.receipt_long_outlined,
                title: 'My Orders',
                subtitle: 'View past orders & track active ones',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.orderHistoryScreen);
                },
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  return _buildProfileOption(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Order updates and announcements',
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.notificationScreen);
                    },
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Preferences and account details',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              const Text('ACCOUNT', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              _buildProfileOption(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of this device',
                iconColor: AppColors.error,
                iconBg: AppColors.errorTint,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Color iconBg = AppColors.primaryTint,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: AppTextStyles.titleSmall),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
          trailing: trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
