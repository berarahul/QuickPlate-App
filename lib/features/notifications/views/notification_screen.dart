import 'package:provider/provider.dart';
import '../../../core/app_exports.dart';
import '../provider/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<NotificationProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'ORDER_STATUS_UPDATE':
        return Icons.restaurant_rounded;
      case 'PAYMENT_VERIFICATION':
        return Icons.check_circle_outline_rounded;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColorForType(String? type) {
    switch (type) {
      case 'ORDER_STATUS_UPDATE':
        return AppColors.primary;
      case 'PAYMENT_VERIFICATION':
        return AppColors.success;
      case 'PROMOTION':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  Color _getIconBgForType(String? type) {
    switch (type) {
      case 'ORDER_STATUS_UPDATE':
        return AppColors.primaryTint;
      case 'PAYMENT_VERIFICATION':
        return AppColors.successTint;
      case 'PROMOTION':
        return AppColors.infoTint;
      default:
        return AppColors.warningTint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => provider.markAllAsRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Read All'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null &&
              provider.notifications.isEmpty) {
            return StateView(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.textTertiary,
              iconBg: AppColors.surfaceAlt,
              title: 'Couldn\'t load notifications',
              message: provider.errorMessage,
              actionLabel: 'Retry',
              onAction: () =>
                  provider.fetchNotifications(isRefresh: true),
            );
          }

          if (provider.notifications.isEmpty) {
            return const StateView(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications Yet',
              message:
                  'Any alerts about your food orders, status changes, or payments will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchNotifications(isRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount:
                  provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = provider.notifications[index];
                final eventType = notification.data?['eventType'] as String?;
                final read = notification.isRead;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    color: read ? AppColors.surface : AppColors.primaryTint,
                    border: Border.all(
                      color: read ? AppColors.border : AppColors.primaryLight,
                    ),
                    onTap: () {
                      if (!read) {
                        provider.markAsRead(notification.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: read
                                  ? AppColors.surfaceAlt
                                  : _getIconBgForType(eventType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForType(eventType),
                              color: read
                                  ? AppColors.textTertiary
                                  : _getIconColorForType(eventType),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: read
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(notification.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: read
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!read)
                            Container(
                              margin: const EdgeInsets.only(left: 6, top: 6),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        onPressed: () {
          final provider = context.read<NotificationProvider>();
          provider.simulateIncomingNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Simulated push notification received!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Simulate Alert'),
      ),
    );
  }
}
