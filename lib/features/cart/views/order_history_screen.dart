import '../provider/order_provider.dart';
import 'order_tracking_screen.dart';
import '../../../core/app_exports.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrderHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.orderHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null &&
              orderProvider.orderHistory.isEmpty) {
            return StateView(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.textTertiary,
              iconBg: AppColors.surfaceAlt,
              title: 'Couldn\'t load orders',
              message: orderProvider.errorMessage,
              actionLabel: 'Retry',
              onAction: () => orderProvider.fetchOrderHistory(),
            );
          }

          if (orderProvider.orderHistory.isEmpty) {
            return const StateView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your past and active orders will show up here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => orderProvider.fetchOrderHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: orderProvider.orderHistory.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orderHistory[index];
                final statusInfo = _getStatusInfo(order.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderTrackingScreen(orderId: order.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: statusInfo.$2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  statusInfo.$1,
                                  color: statusInfo.$3,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.id.length >= 6
                                          ? 'Order #${order.id.substring(order.id.length - 6)}'
                                          : 'Order #${order.id}',
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order.items.length} items',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                '₹${order.totalAmount}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo.$2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatStatus(order.status),
                              style: TextStyle(
                                color: statusInfo.$3,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
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
    );
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Returns (icon, bgColor, fgColor).
  (IconData, Color, Color) _getStatusInfo(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'WAITING_FOR_CASH':
      case 'AWAITING_ONLINE_PAYMENT':
        return (
          Icons.access_time_rounded,
          AppColors.warningTint,
          AppColors.warning,
        );
      case 'PENDING':
      case 'PLACED':
        return (Icons.receipt_outlined, AppColors.infoTint, AppColors.info);
      case 'PREPARING':
      case 'IN_KITCHEN':
        return (
          Icons.local_fire_department_outlined,
          AppColors.primaryTint,
          AppColors.primary,
        );
      case 'READY':
      case 'READY_FOR_PICKUP':
        return (
          Icons.check_circle_outline_rounded,
          AppColors.successTint,
          AppColors.success,
        );
      case 'DELIVERED':
      case 'COMPLETED':
        return (
          Icons.done_all_rounded,
          AppColors.surfaceAlt,
          AppColors.textSecondary,
        );
      case 'CANCELLED':
        return (Icons.cancel_outlined, AppColors.errorTint, AppColors.error);
      default:
        return (
          Icons.receipt_outlined,
          AppColors.surfaceAlt,
          AppColors.textSecondary,
        );
    }
  }
}
