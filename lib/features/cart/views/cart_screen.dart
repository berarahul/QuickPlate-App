import '../provider/cart_provider.dart';
import '../provider/order_provider.dart';
import '../../scan/provider/scan_provider.dart';
import '../../table_reservation/provider/table_reservation_provider.dart';
import '../../../core/app_exports.dart';
import 'widgets/cart_item_tile.dart';
import 'widgets/cart_payment_option.dart';
import 'widgets/cart_checkout_bar.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showOrderSuccess(
    BuildContext context,
    String message, {
    bool isOnline = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.successTint,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: AppColors.success, size: 32),
        ),
        title: const Text('Order Placed!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CartProvider>().clearCart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePayment(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final scanProvider = context.read<ScanProvider>();
    final orderProvider = context.read<OrderProvider>();
    final reservationProvider = context.read<TableReservationProvider>();

    final sessionData = scanProvider.sessionResponse?.data;
    final liveSession = sessionData?.session;
    final activeReservation = reservationProvider.activeReservation;

    final tableId = liveSession?.tableId ?? activeReservation?.tableId;
    final reservationId = activeReservation?.id;

    if (tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please scan a table QR code or reserve a seat first!',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final isCheckedIn = (liveSession != null && liveSession.isActive == true) ||
        (activeReservation?.reservationStatus.toLowerCase() == 'checked_in');

    if (!isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please scan the table QR code at Table $tableId to check in and start your session before placing an order.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (activeReservation != null &&
        activeReservation.reservationStatus.toLowerCase() != 'cancelled') {
      try {
        final now = DateTime.now();
        final start = DateTimeFormatter.parseDateTime(activeReservation.startTime) ?? now;
        final end = DateTimeFormatter.parseDateTime(activeReservation.endTime) ?? now;

        if (now.isBefore(start)) {
          final startFormatted = DateTimeFormatter.formatTime(start);
          final endFormatted = DateTimeFormatter.formatTime(end);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Orders can only be placed during your reserved table slot ($startFormatted - $endFormatted). Your time slot has not started yet.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (now.isAfter(end)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your reserved time slot for Table ${activeReservation.tableId} has expired.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      } catch (_) {}
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Payment Method',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how you\'d like to pay for this order.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CartPaymentOption(
              icon: Icons.payments_outlined,
              title: 'Pay Cash at Counter',
              subtitle: 'Pay in person when you collect',
              onTap: () async {
                Navigator.pop(ctx);
                final success = await orderProvider.placeCashOrder(
                  tableId: tableId,
                  items: cart.orderItems,
                  reservationId: reservationId,
                );
                if (!context.mounted) return;
                if (success) {
                  _showOrderSuccess(
                    context,
                    'Please visit the counter to pay cash and confirm your order.',
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        orderProvider.errorMessage ?? 'Order failed',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            CartPaymentOption(
              icon: Icons.credit_card_rounded,
              title: 'Pay Online (Razorpay)',
              subtitle: 'UPI, cards & wallets',
              onTap: () async {
                Navigator.pop(ctx);
                await orderProvider.initiateOnlineOrder(
                  tableId: tableId,
                  items: cart.orderItems,
                  reservationId: reservationId,
                  onPaymentCompleted: (success, message) {
                    if (!context.mounted) return;
                    if (success) {
                      _showOrderSuccess(
                        context,
                        'Your payment was successful and order is being prepared!',
                        isOnline: true,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message ?? 'Payment failed'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          Text('Your Cart', style: AppTextStyles.displayLarge),
                        ],
                      ),
                      const Spacer(),
                      if (cart.items.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear Cart',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: AppColors.error,
                          ),
                          onPressed: () => cart.clearCart(),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: cart.items.isEmpty
                      ? const StateView(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Your cart is empty',
                          message:
                              'Browse the menu and add items to get started.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items.values.toList()[index];
                            return CartItemTile(item: item);
                          },
                        ),
                ),
                if (cart.items.isNotEmpty)
                  CartCheckoutBar(
                    onCheckout: () => _handlePayment(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
