import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/table_availability_model.dart';
import '../models/table_reservation_model.dart';
import '../repository/table_reservation_repository.dart';
import '../../../core/network/api_exceptions.dart';

class TableReservationProvider extends ChangeNotifier {
  final TableReservationRepository _repository;
  late Razorpay _razorpay;
  Function(TableReservation? reservation, String? errorMessage)? _onPaymentCompleted;

  TableReservationProvider(this._repository) {
    _initCurrentTime();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initCurrentTime() {
    final now = DateTime.now();
    const closeMin = 17 * 60; // 5 PM
    final nowMin = now.hour * 60 + now.minute;

    if (nowMin >= closeMin) {
      _selectedStartTime = '09:00';
      _selectedEndTime = '10:00';
    } else {
      final startH = now.hour < 9 ? 9 : now.hour;
      final startM = (now.minute ~/ 15) * 15;
      _selectedStartTime = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
      
      final endMin = (startH * 60 + startM + 60 > closeMin) ? closeMin : (startH * 60 + startM + 60);
      final endH = (endMin ~/ 60).toString().padLeft(2, '0');
      final endM = (endMin % 60).toString().padLeft(2, '0');
      _selectedEndTime = '$endH:$endM';
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Search Filters
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  String get selectedDate => _selectedDate;

  String _selectedStartTime = '09:00';
  String get selectedStartTime => _selectedStartTime;

  String _selectedEndTime = '10:00';
  String get selectedEndTime => _selectedEndTime;

  int get selectedDuration {
    try {
      final s = _selectedStartTime.split(':').map(int.parse).toList();
      final e = _selectedEndTime.split(':').map(int.parse).toList();
      final startMin = s[0] * 60 + s[1];
      final endMin = e[0] * 60 + e[1];
      final diff = endMin - startMin;
      return diff >= 15 ? diff : 30;
    } catch (_) {
      return 60;
    }
  }

  // Availability Result
  TableAvailabilityResponse? _availabilityResponse;
  TableAvailabilityResponse? get availabilityResponse => _availabilityResponse;

  // Seat Selection State
  String? _selectedTableId;
  String? get selectedTableId => _selectedTableId;

  final Set<int> _selectedSeats = {};
  Set<int> get selectedSeats => _selectedSeats;

  // User's Reservations
  List<TableReservation> _myReservations = [];
  List<TableReservation> get myReservations => _myReservations;

  // Active reservation linked for Cart deposit credit
  TableReservation? _activeReservation;
  TableReservation? get activeReservation => _activeReservation;

  void setSearchDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSearchStartTime(String startTime) {
    _selectedStartTime = startTime;
    notifyListeners();
  }

  void setTimeRange(String startTime, String endTime) {
    _selectedStartTime = startTime;
    _selectedEndTime = endTime;
    notifyListeners();
  }

  void selectTable(String tableId) {
    if (_selectedTableId != tableId) {
      _selectedTableId = tableId;
      _selectedSeats.clear();
      notifyListeners();
    }
  }

  void toggleSeatSelection(int seatNumber) {
    if (_selectedSeats.contains(seatNumber)) {
      _selectedSeats.remove(seatNumber);
    } else {
      _selectedSeats.add(seatNumber);
    }
    notifyListeners();
  }

  void clearSeatSelection() {
    _selectedSeats.clear();
    _selectedTableId = null;
    notifyListeners();
  }

  Future<void> fetchAvailableTables() async {
    _setLoading(true);
    _errorMessage = null;
    _selectedTableId = null;
    _selectedSeats.clear();

    try {
      _availabilityResponse = await _repository.getAvailableTables(
        date: _selectedDate,
        startTime: _selectedStartTime,
        durationMinutes: selectedDuration,
      );
      if (_availabilityResponse?.tables.isNotEmpty ?? false) {
        _selectedTableId = _availabilityResponse!.tables.first.tableId;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load available tables';
    } finally {
      _setLoading(false);
    }
  }

  Future<TableReservation?> reserveSeats({String paymentMethod = 'offline'}) async {
    if (_selectedTableId == null || _selectedSeats.isEmpty) {
      _errorMessage = 'Please select a table and at least one seat';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final reservation = await _repository.reserveTable(
        tableId: _selectedTableId!,
        seatNumbers: _selectedSeats.toList()..sort(),
        reservationDate: _selectedDate,
        startTime: _selectedStartTime,
        durationMinutes: selectedDuration,
        paymentMethod: paymentMethod,
      );

      _activeReservation = reservation;
      await fetchMyReservations();
      return reservation;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to make reservation: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initiateRazorpayReservation({
    required double depositAmount,
    required Function(TableReservation? reservation, String? errorMessage) onCompleted,
  }) async {
    if (_selectedTableId == null || _selectedSeats.isEmpty) {
      onCompleted(null, 'Please select a table and at least one seat');
      return;
    }

    _onPaymentCompleted = onCompleted;
    _setLoading(true);

    final key = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    if (key.isEmpty || key == 'rzp_test_your_key_here') {
      // Direct fallback if key is placeholder or unconfigured
      final reservation = await reserveSeats(paymentMethod: 'RAZORPAY');
      _setLoading(false);
      onCompleted(reservation, reservation == null ? errorMessage : null);
      return;
    }

    var options = {
      'key': key,
      'amount': (depositAmount * 100).toInt(),
      'name': 'Quick Plate',
      'description': 'Table Booking Deposit',
      'timeout': 300,
      'prefill': {'contact': '', 'email': ''},
    };

    try {
      _setLoading(false);
      _razorpay.open(options);
    } catch (e) {
      _setLoading(false);
      onCompleted(null, 'Could not open Razorpay gateway: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _setLoading(true);
    try {
      final reservation = await _repository.reserveTable(
        tableId: _selectedTableId!,
        seatNumbers: _selectedSeats.toList()..sort(),
        reservationDate: _selectedDate,
        startTime: _selectedStartTime,
        durationMinutes: selectedDuration,
        paymentMethod: 'RAZORPAY',
        razorpayOrderId: response.orderId,
        razorpayPaymentId: response.paymentId,
      );

      _activeReservation = reservation;
      await fetchMyReservations();
      _onPaymentCompleted?.call(reservation, null);
    } on ApiException catch (e) {
      _onPaymentCompleted?.call(null, e.message);
    } catch (e) {
      _onPaymentCompleted?.call(null, 'Failed to confirm reservation: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onPaymentCompleted?.call(null, response.message ?? 'Payment Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onPaymentCompleted?.call(null, 'External wallet not supported');
  }

  Future<TableReservation?> checkInWithQR(String qrData) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final reservation = await _repository.qrCheckIn(qrData);
      _activeReservation = reservation;
      await fetchMyReservations();
      return reservation;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to check-in via QR';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyReservations() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _myReservations = await _repository.getMyReservations();
      // Find active confirmed/checked_in reservation if present
      final activeList = _myReservations.where(
        (r) => r.reservationStatus == 'booked' || r.reservationStatus == 'checked_in',
      ).toList();
      if (activeList.isNotEmpty) {
        _activeReservation = activeList.first;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load reservations';
    } finally {
      _setLoading(false);
    }
  }

  void setActiveReservation(TableReservation? reservation) {
    _activeReservation = reservation;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
