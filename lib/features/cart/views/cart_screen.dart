import '../provider/cart_provider.dart';
import '../provider/order_provider.dart';
import '../../scan/provider/scan_provider.dart';
import '../../table_reservation/provider/table_reservation_provider.dart';
import '../../../core/app_exports.dart';

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
              // Navigate to history or tracking
              // For now just clear cart
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

    // Requirement #1: Must be checked in via QR scan
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

    // Requirement #2: Must be within reserved time slot
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
            _PaymentOption(
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
            _PaymentOption(
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
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 22,
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTint,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.lunch_dining_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: AppTextStyles.titleSmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${item.price} each',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _QtyStepper(
                                      quantity: item.quantity,
                                      onAdd: () =>
                                          cart.incrementItem(item.foodId),
                                      onRemove: () =>
                                          cart.removeSingleItem(item.foodId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (cart.items.isNotEmpty) _checkoutBar(cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _checkoutBar(CartProvider cart) {
    return Builder(
      builder: (context) {
        final reservation = context
            .watch<TableReservationProvider>()
            .activeReservation;
        final depositCredit = reservation?.depositPaidAmount ?? 0.0;
        final depositDiscount =
            (depositCredit > 0 && cart.totalAmount > depositCredit)
            ? depositCredit
            : 0.0;
        final netAmount = cart.totalAmount - depositDiscount;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 86),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppColors.cardShadow,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (depositCredit > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cart Total', style: AppTextStyles.bodySmall),
                          Text(
                            '₹${cart.totalAmount}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                depositDiscount > 0
                                    ? 'Table Deposit Discount'
                                    : 'Table Deposit (Min Food Bill > ₹${depositCredit.toStringAsFixed(0)} to apply)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            depositDiscount > 0
                                ? '-₹${depositDiscount.toStringAsFixed(0)}'
                                : '₹0',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: depositDiscount > 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Payable Total',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(
                                '₹${netAmount.toStringAsFixed(0)}',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomElevatedButton(
                            text: orderProvider.isLoading
                                ? 'Processing...'
                                : 'Place Order',
                            loading: orderProvider.isLoading,
                            onPressed: orderProvider.isLoading
                                ? null
                                : () => _handlePayment(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onRemove,
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            color: AppColors.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
