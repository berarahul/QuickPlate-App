import '../../../../core/app_exports.dart';
import '../../provider/cart_provider.dart';
import '../../provider/order_provider.dart';
import '../../../table_reservation/provider/table_reservation_provider.dart';

class CartCheckoutBar extends StatelessWidget {
  final VoidCallback onCheckout;

  const CartCheckoutBar({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final reservation =
        context.watch<TableReservationProvider>().activeReservation;
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
                        onPressed: orderProvider.isLoading ? null : onCheckout,
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
  }
}
