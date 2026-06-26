class CheckoutResponse {
  final String orderId;
  final String gatewayOrderId;
  final double totalAmount;

  CheckoutResponse({
    required this.orderId,
    required this.gatewayOrderId,
    required this.totalAmount,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    // The API returns the order details nested inside an 'order' object
    final order = json['order'] as Map<String, dynamic>?;

    if (order != null) {
      return CheckoutResponse(
        orderId: order['_id'] ?? '',
        gatewayOrderId: order['paymentGatewayOrderId'] ?? '',
        totalAmount: (order['totalAmount'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return CheckoutResponse(
      orderId: json['orderId'] ?? '',
      gatewayOrderId: json['gatewayOrderId'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentVerifyRequest {
  final String orderId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  PaymentVerifyRequest({
    required this.orderId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}
