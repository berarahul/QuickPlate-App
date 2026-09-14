import '../../../core/app_exports.dart';
import '../../notifications/provider/notification_provider.dart';
import '../../auth/provider/auth_provider.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/logout_dialog.dart';
import 'widgets/profile_option_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!context.mounted) return;
            await context.read<AuthProvider>().fetchProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text('Profile', style: AppTextStyles.displayLarge),
                const SizedBox(height: 24),
                // Profile header card
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final avatarUrl = authProvider.userIdCardImage;
                    return AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.person_rounded,
                                        size: 34,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 34,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.userName ?? 'Student Name',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  authProvider.userEmail ?? 'student@email.com',
                                  style: AppTextStyles.bodySmall,
                                ),
                                if (authProvider.userPhone != null &&
                                    authProvider.userPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    authProvider.userPhone!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Edit Profile',
                            onPressed: () => EditProfileSheet.show(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('ACTIVITY', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                ProfileOptionTile(
                  icon: Icons.table_restaurant_outlined,
                  title: 'Table & Seat Reservations',
                  subtitle: 'Reserve seats in advance & manage bookings',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.tableReservationScreen,
                    );
                  },
                ),
                ProfileOptionTile(
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
                    return ProfileOptionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Order updates and announcements',
                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
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
                        Navigator.pushNamed(
                          context,
                          AppRoutes.notificationScreen,
                        );
                      },
                    );
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ProfileOptionTile(
                      icon: themeProvider.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      title: 'Dark Theme',
                      subtitle: themeProvider.isDarkMode
                          ? 'Dark mode enabled'
                          : 'Dark mode disabled',
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryTint,
                      onTap: () {
                        themeProvider.toggleTheme(!themeProvider.isDarkMode);
                      },
                      trailing: Switch.adaptive(
                        value: themeProvider.isDarkMode,
                        activeTrackColor: AppColors.primary,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'ACCOUNT',
                  style: AppTextStyles.labelSmall.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ProfileOptionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Update your name, phone & photo',
                  onTap: () => EditProfileSheet.show(context),
                ),
                ProfileOptionTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of this device',
                  iconColor: AppColors.error,
                  iconBg: AppColors.error.withValues(alpha: 0.1),
                  onTap: () => LogoutDialog.show(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
