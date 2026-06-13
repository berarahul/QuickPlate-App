import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders', style: AppTextStyles.titleLarge),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.orderHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.errorMessage != null && orderProvider.orderHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(orderProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => orderProvider.fetchOrderHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (orderProvider.orderHistory.isEmpty) {
            return const Center(
              child: Text('No orders yet', style: AppTextStyles.bodyLarge),
            );
          }

          return RefreshIndicator(
            onRefresh: () => orderProvider.fetchOrderHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.orderHistory.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orderHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      order.id.length >= 6 
                        ? 'Order #${order.id.substring(order.id.length - 6)}'
                        : 'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${order.items.length} items • ₹${order.totalAmount}'),
                        Text(
                          'Status: ${order.status}',
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(orderId: order.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'WAITING_FOR_CASH':
      case 'AWAITING_ONLINE_PAYMENT':
        return Colors.orange;
      case 'PENDING':
      case 'PLACED':
        return Colors.blue;
      case 'PREPARING':
      case 'IN_KITCHEN':
        return Colors.purple;
      case 'READY':
      case 'READY_FOR_PICKUP':
        return Colors.green;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
