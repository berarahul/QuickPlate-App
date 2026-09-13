import '../provider/order_provider.dart';
import '../models/order_model.dart';
import '../../scan/provider/scan_provider.dart';
import '../../table_reservation/provider/table_reservation_provider.dart';
import '../../../core/app_exports.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    context.read<OrderProvider>().clearOrderDetails();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    await context.read<OrderProvider>().fetchOrderDetails(widget.orderId);
  }

  void _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order?\n(Orders can only be cancelled within 5 minutes of creation)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final success = await context.read<OrderProvider>().cancelOrder(
        widget.orderId,
      );
      if (!mounted) return;
      if (success) {
        context.read<ScanProvider>().clearSession();
        context.read<TableReservationProvider>().fetchMyReservations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to cancel order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Tracking')),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.orderDetails == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderProvider.orderDetails;
          if (order == null) {
            return StateView(
              icon: Icons.error_outline_rounded,
              iconColor: AppColors.error,
              iconBg: AppColors.errorTint,
              title: 'Order not found',
              message: orderProvider.errorMessage,
            );
          }

          final upperStatus = order.status.toUpperCase();

          return RefreshIndicator(
            onRefresh: _fetchDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live status banner
                  _StatusBanner(status: order.status),
                  const SizedBox(height: 20),
                  _buildOrderInfo(order),
                  const SizedBox(height: 28),
                  Text('Order Status', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 16),
                  _buildStatusTimeline(order),
                  const SizedBox(height: 28),
                  if (upperStatus == 'WAITING_FOR_CASH' ||
                      upperStatus == 'PENDING')
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo(OrderResponse order) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID', style: AppTextStyles.bodyMedium),
              Text(
                '#${order.id.substring(order.id.length - 8)}',
                style: AppTextStyles.titleSmall,
              ),
            ],
          ),
          const Divider(height: 24),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.quantity}x Item ID: ${item.foodId.substring(0, 5)}...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: AppTextStyles.titleSmall),
              Text(
                '₹${order.totalAmount}',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if ((order.status.toUpperCase() == 'DELIVERED' || order.status.toUpperCase() == 'COMPLETED') &&
              (order.paymentStatus.toUpperCase() == 'PAID' || order.paymentStatus.toUpperCase() == 'COMPLETED')) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Done eating? Tap below to release your table seat for others!',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final scanProvider = context.read<ScanProvider>();
                        final res = await scanProvider.leaveTableSession();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.black),
                      label: const Text(
                        'Finish Meal & Leave Table',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(OrderResponse order) {
    final status = order.status.toUpperCase();
    if (status == 'CANCELLED') {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_outlined, color: AppColors.error),
              ),
              const SizedBox(height: 12),
              Text('Order Cancelled', style: AppTextStyles.titleMedium),
            ],
          ),
        ),
      );
    }

    final steps = <(String, IconData, String)>[
      ('Order Placed', Icons.receipt_outlined, 'WAITING_FOR_CASH/PENDING'),
      ('Preparing', Icons.local_fire_department_outlined, 'PREPARING'),
      ('Ready for Pickup', Icons.check_circle_outline_rounded, 'READY'),
      ('Delivered', Icons.done_all_rounded, 'DELIVERED'),
    ];

    int currentStep = 0;
    if (status == 'PREPARING') currentStep = 1;
    if (status == 'READY') currentStep = 2;
    if (status == 'DELIVERED') currentStep = 3;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep && status != 'DELIVERED';
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.surfaceAlt,
                      border: isCurrent
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 4,
                            )
                          : null,
                    ),
                    child: Icon(
                      steps[index].$2,
                      size: 16,
                      color: isCompleted
                          ? AppColors.white
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: index < currentStep
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index].$1,
                        style: TextStyle(
                          fontWeight: isCompleted
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'In progress...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _info(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.$2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.$3),
      ),
      child: Row(
        children: [
          Icon(info.$1, color: info.$4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _format(status),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: info.$4,
                    fontSize: 15,
                  ),
                ),
                Text(info.$5, style: TextStyle(color: info.$4, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');

  (IconData, Color, Color, Color, String) _info(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PREPARING':
      case 'IN_KITCHEN':
        return (
          Icons.local_fire_department_outlined,
          AppColors.primaryTint,
          AppColors.primaryLight,
          AppColors.primary,
          'The kitchen is preparing your food.',
        );
      case 'READY':
      case 'READY_FOR_PICKUP':
        return (
          Icons.check_circle_outline_rounded,
          AppColors.successTint,
          AppColors.success,
          AppColors.success,
          'Your order is ready. Please collect it.',
        );
      case 'DELIVERED':
      case 'COMPLETED':
        return (
          Icons.done_all_rounded,
          AppColors.surfaceAlt,
          AppColors.border,
          AppColors.textSecondary,
          'This order has been completed.',
        );
      default:
        return (
          Icons.access_time_rounded,
          AppColors.warningTint,
          AppColors.warning,
          AppColors.warning,
          'Waiting for confirmation.',
        );
    }
  }
}
