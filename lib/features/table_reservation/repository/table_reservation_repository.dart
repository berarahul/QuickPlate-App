import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/table_availability_model.dart';
import '../models/table_reservation_model.dart';

class TableReservationRepository {
  final ApiClient _apiClient;

  TableReservationRepository(this._apiClient);

  Future<TableAvailabilityResponse> getAvailableTables({
    required String date,
    required String startTime,
    int durationMinutes = 60,
  }) async {
    final timeStr = startTime.length == 5 ? startTime : startTime.padLeft(5, '0');
    final formattedStartTime = '${date}T$timeStr:00';

    final response = await _apiClient.get(
      ApiEndpoints.availableTables,
      queryParameters: {
        'startTime': formattedStartTime,
        'durationHours': (durationMinutes / 60.0).toStringAsFixed(1),
      },
    );

    final data = response.data['data'];
    if (data == null) {
      throw DefaultException(
        response.data['message'] ?? 'Failed to fetch available tables',
      );
    }

    return TableAvailabilityResponse.fromJson(data);
  }

  Future<TableReservation> reserveTable({
    required String tableId,
    required List<int> seatNumbers,
    required String reservationDate,
    required String startTime,
    int durationMinutes = 60,
    String paymentMethod = 'offline',
    String? razorpayOrderId,
    String? razorpayPaymentId,
  }) async {
    final timeStr = startTime.length == 5 ? startTime : startTime.padLeft(5, '0');
    final formattedStartTime = '${reservationDate}T$timeStr:00';

    final response = await _apiClient.post(
      ApiEndpoints.reserveTable,
      data: {
        'tableId': tableId,
        'seatsBooked': seatNumbers.length,
        'seatNumbers': seatNumbers,
        'reservationDate': reservationDate,
        'startTime': formattedStartTime,
        'durationHours': (durationMinutes / 60.0),
        'paymentMethod': paymentMethod,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      },
    );

    debugPrint('reserveTable response: ${response.data}');

    final data = response.data['data'];
    if (data == null) {
      throw DefaultException(
        response.data['message'] ?? 'Failed to reserve table',
      );
    }

    return TableReservation.fromJson(data);
  }

  Future<TableReservation> qrCheckIn(String qrData) async {
    final response = await _apiClient.post(
      ApiEndpoints.qrCheckIn,
      data: {'qrData': qrData},
    );

    final data = response.data['data'];
    if (data == null) {
      throw DefaultException(
        response.data['message'] ?? 'Check-in failed',
      );
    }

    return TableReservation.fromJson(data);
  }

  Future<List<TableReservation>> getMyReservations() async {
    final response = await _apiClient.get(ApiEndpoints.myReservations);

    final List? data = response.data['data'];
    if (data == null) return [];

    return data.map((r) => TableReservation.fromJson(r)).toList();
  }
}
