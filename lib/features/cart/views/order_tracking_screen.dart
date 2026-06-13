import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/order_provider.dart';
import '../models/order_model.dart';
import '../../../core/app_exports.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    // Poll every 30 seconds for status updates
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDetails();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    context.read<OrderProvider>().clearOrderDetails();
    super.dispose();
  }

  void _fetchDetails() {
    if (!mounted) return;
    context.read<OrderProvider>().fetchOrderDetails(widget.orderId);
  }

  void _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<OrderProvider>().cancelOrder(widget.orderId);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to cancel order'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Tracking', style: AppTextStyles.titleLarge),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.orderDetails == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderProvider.orderDetails;
          if (order == null) {
            return Center(
              child: Text(
                orderProvider.errorMessage ?? 'Order not found',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderInfo(order),
                const SizedBox(height: 32),
                const Text('Order Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStatusTimeline(order),
                const SizedBox(height: 32),
                if (order.status == 'WAITING_FOR_CASH' || order.status == 'PENDING')
                  ElevatedButton(
                    onPressed: () => _handleCancel(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel Order'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo(OrderResponse order) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ID', style: TextStyle(color: Colors.grey.shade600)),
                Text('#${order.id.substring(order.id.length - 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x Item ID: ${item.foodId.substring(0, 5)}...'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${order.totalAmount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(OrderResponse order) {
    final steps = ['WAITING_FOR_CASH/PENDING', 'PREPARING', 'READY', 'DELIVERED'];
    int currentStep = 0;
    if (order.status == 'PREPARING') currentStep = 1;
    if (order.status == 'READY') currentStep = 2;
    if (order.status == 'DELIVERED') currentStep = 3;
    if (order.status == 'CANCELLED') {
        return const Center(child: Text('ORDER CANCELLED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    }

    return Column(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentStep;
        bool isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: index < currentStep ? AppColors.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
