import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart';
import '../provider/order_provider.dart';
import '../../scan/provider/scan_provider.dart';
import '../../../core/app_exports.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showOrderSuccess(BuildContext context, String message, {bool isOnline = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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

    final tableId = scanProvider.sessionResponse?.data?.table?.tableId;

    debugPrint('Placing order for tableId: $tableId');
    debugPrint('Cart items: ${cart.orderItems.length}');

    if (tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan a table QR code first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Payment Method',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await orderProvider.placeCashOrder(
                  tableId: tableId,
                  items: cart.orderItems,
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
                      content: Text(orderProvider.errorMessage ?? 'Order failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.money),
              label: const Text('Pay Cash at Counter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await orderProvider.initiateOnlineOrder(
                  tableId: tableId,
                  items: cart.orderItems,
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
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay Online (Razorpay)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => context.read<CartProvider>().clearCart(),
          )
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items.values.toList()[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('₹${item.price} x ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.removeSingleItem(item.foodId),
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cart.incrementItem(item.foodId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: AppTextStyles.bodyLarge),
                        Text(
                          '₹${cart.totalAmount}',
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) {
                        return CustomElevatedButton(
                          text: orderProvider.isLoading ? 'Processing...' : 'Place Order',
                          onPressed: orderProvider.isLoading ? null : () => _handlePayment(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
