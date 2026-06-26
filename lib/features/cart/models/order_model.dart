import 'order_item.dart';

class OrderRequest {
  final String tableId;
  final List<OrderItem> items;
  final String? paymentMethod;
  final double studentLatitude;
  final double studentLongitude;

  OrderRequest({
    required this.tableId,
    required this.items,
    this.paymentMethod,
    required this.studentLatitude,
    required this.studentLongitude,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'tableId': tableId,
      'items': items.map((i) => i.toJson()).toList(),
      'studentLatitude': studentLatitude,
      'studentLongitude': studentLongitude,
    };
    if (paymentMethod != null) {
      data['paymentMethod'] = paymentMethod!;
    }
    return data;
  }
}

class OrderResponse {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final String status;
  final double totalAmount;
  final List<StatusTimeline>? statusTimeline;
  final DateTime createdAt;

  OrderResponse({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.statusTimeline,
    required this.createdAt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return OrderResponse(
      id: json['_id'] ?? json['id'] ?? '',
      tableId: json['tableId'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : [],
      status: json['status'] ?? 'UNKNOWN',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      statusTimeline: json['statusTimeline'] != null
          ? (json['statusTimeline'] as List)
                .map((s) => StatusTimeline.fromJson(s))
                .toList()
          : null,
      createdAt: parseDate(json['createdAt']),
    );
  }
}

class StatusTimeline {
  final String status;
  final DateTime timestamp;
  final String? message;

  StatusTimeline({required this.status, required this.timestamp, this.message});

  factory StatusTimeline.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return StatusTimeline(
      status: json['status'] ?? '',
      timestamp: parseDate(json['timestamp']),
      message: json['message'],
    );
  }
}
