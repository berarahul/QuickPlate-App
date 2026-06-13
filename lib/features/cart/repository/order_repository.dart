import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/order_model.dart';
import '../models/payment_models.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<OrderResponse> placeCashOrder(OrderRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.studentOrders,
      data: request.toJson(),
    );
    debugPrint('placeCashOrder response: ${response.data}');
    
    final data = response.data['data'];
    if (data == null) {
      throw DefaultException(response.data['message'] ?? 'Failed to place cash order');
    }
    return OrderResponse.fromJson(data);
  }

  Future<CheckoutResponse> initiateCheckout(OrderRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.checkout,
      data: request.toJson(),
    );
    debugPrint('initiateCheckout response: ${response.data}');
    
    final data = response.data['data'];
    if (data == null) {
      throw DefaultException(response.data['message'] ?? 'Failed to initiate checkout');
    }
    return CheckoutResponse.fromJson(data);
  }

  Future<bool> verifyPayment(PaymentVerifyRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyPayment,
      data: request.toJson(),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<OrderResponse>> getOrderHistory({String? status}) async {
    final Map<String, dynamic> queryParams = {};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.studentOrders,
      queryParameters: queryParams,
    );
    
    final List? data = response.data['data'];
    if (data == null) return [];
    
    return data.map((o) => OrderResponse.fromJson(o)).toList();
  }

  Future<OrderResponse> getOrderDetails(String orderId) async {
    final response = await _apiClient.get(ApiEndpoints.orderDetails(orderId));
    return OrderResponse.fromJson(response.data['data']);
  }

  Future<void> cancelOrder(String orderId) async {
    await _apiClient.patch(ApiEndpoints.cancelOrder(orderId), data: {});
  }
}
