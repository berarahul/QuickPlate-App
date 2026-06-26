import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/order_model.dart';
import '../models/order_item.dart';
import '../models/payment_models.dart';
import '../repository/order_repository.dart';
import '../../../core/network/api_exceptions.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  late Razorpay _razorpay;

  OrderProvider(this._orderRepository) {
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  OrderResponse? _currentOrder;
  OrderResponse? get currentOrder => _currentOrder;

  OrderResponse? _orderDetails;
  OrderResponse? get orderDetails => _orderDetails;

  List<OrderResponse> _orderHistory = [];
  List<OrderResponse> get orderHistory => _orderHistory;

  CheckoutResponse? _checkoutData;

  // For Razorpay success handling
  Function(bool success, String? message)? _onPaymentCompleted;

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, ask user to enable it.
      _errorMessage =
          'Location services are disabled. Please enable GPS and try again.';
      notifyListeners();
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage =
            'Location permissions are denied. Please allow location access to proceed.';
        notifyListeners();
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _errorMessage =
          'Location permissions are permanently denied. Please enable them in settings.';
      notifyListeners();
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Fallback to last known position if current position fails (e.g. timeout)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      _errorMessage = 'Could not determine your location. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> placeCashOrder({
    required String tableId,
    required List<OrderItem> items,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final position = await _getCurrentLocation();
      if (position == null) return false;

      final request = OrderRequest(
        tableId: tableId,
        items: items,
        paymentMethod: 'offline',
        studentLatitude: position.latitude,
        studentLongitude: position.longitude,
      );

      _currentOrder = await _orderRepository.placeCashOrder(request);
      return true;
    } on ApiException catch (e) {
      debugPrint('ApiException in placeCashOrder: ${e.message}');
      _errorMessage = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('Unexpected error in placeCashOrder: $e');
      debugPrint('Stack trace: $stack');
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initiateOnlineOrder({
    required String tableId,
    required List<OrderItem> items,
    required Function(bool success, String? message) onPaymentCompleted,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _onPaymentCompleted = onPaymentCompleted;

    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        _onPaymentCompleted?.call(false, _errorMessage);
        return;
      }

      final request = OrderRequest(
        tableId: tableId,
        items: items,
        studentLatitude: position.latitude,
        studentLongitude: position.longitude,
      );

      _checkoutData = await _orderRepository.initiateCheckout(request);

      if (_checkoutData != null) {
        _setLoading(false);
        // Small delay to let UI settle before launching native Razorpay activity
        await Future.delayed(const Duration(milliseconds: 100));
        _openRazorpay(_checkoutData!);
      }
    } on ApiException catch (e) {
      debugPrint('ApiException in initiateOnlineOrder: ${e.message}');
      _errorMessage = e.message;
      _onPaymentCompleted?.call(false, _errorMessage);
    } catch (e, stack) {
      debugPrint('Unexpected error in initiateOnlineOrder: $e');
      debugPrint('Stack trace: $stack');
      _errorMessage = 'An unexpected error occurred: $e';
      _onPaymentCompleted?.call(false, _errorMessage);
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  void _openRazorpay(CheckoutResponse checkout) {
    final key = dotenv.env['RAZORPAY_KEY_ID'] ?? '';

    if (key.isEmpty || key == 'rzp_test_your_key_here') {
      debugPrint(
        'Error: Razorpay Key is missing or using placeholder in .env file',
      );
      _onPaymentCompleted?.call(
        false,
        'Payment configuration error. Please check RAZORPAY_KEY_ID.',
      );
      return;
    }

    var options = {
      'key': key,
      'amount': (checkout.totalAmount * 100).toInt(),
      'name': 'Quick Plate',
      'order_id': checkout.gatewayOrderId,
      'description': 'Food Order Payment',
      'timeout': 300, // in seconds
      'prefill': {'contact': '', 'email': ''},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      _onPaymentCompleted?.call(false, 'Could not open payment gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _setLoading(true);
    try {
      final verifyRequest = PaymentVerifyRequest(
        orderId: _checkoutData!.orderId,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      final success = await _orderRepository.verifyPayment(verifyRequest);
      if (success) {
        _onPaymentCompleted?.call(true, 'Payment Successful');
      } else {
        _onPaymentCompleted?.call(false, 'Payment verification failed');
      }
    } on ApiException catch (e) {
      _onPaymentCompleted?.call(false, e.message);
    } catch (e) {
      _onPaymentCompleted?.call(
        false,
        'An unexpected error occurred during verification',
      );
    } finally {
      _setLoading(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onPaymentCompleted?.call(false, response.message ?? 'Payment Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onPaymentCompleted?.call(false, 'External wallet not supported');
  }

  Future<void> fetchOrderHistory({String? status}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _orderHistory = await _orderRepository.getOrderHistory(status: status);
      debugPrint('Fetched ${_orderHistory.length} orders');
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('ApiException in fetchOrderHistory: ${e.message}');
    } catch (e, stack) {
      _errorMessage = 'Failed to load order history';
      debugPrint('Error in fetchOrderHistory: $e');
      debugPrint('Stack trace: $stack');
    } finally {
      _setLoading(false);
    }
  }

  Future<OrderResponse?> fetchOrderDetails(String orderId) async {
    _setLoading(true);
    try {
      _orderDetails = await _orderRepository.getOrderDetails(orderId);
      return _orderDetails;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to load order details';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _orderRepository.cancelOrder(orderId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to cancel order';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearOrderDetails() {
    _orderDetails = null;
    notifyListeners();
  }
}
