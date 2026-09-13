import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../model/table_session_request.dart';
import '../model/table_session_response.dart';
import '../repository/scan_repository.dart';
import '../../../core/network/api_exceptions.dart';

class ScanProvider extends ChangeNotifier {
  final ScanRepository _scanRepository;
  Razorpay? _razorpay;

  ScanProvider(this._scanRepository);

  Razorpay get razorpay {
    if (_razorpay == null) {
      _razorpay = Razorpay();
      _razorpay!.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        _handleRazorpayPaymentSuccess,
      );
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayPaymentError);
      _razorpay!.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        _handleRazorpayExternalWallet,
      );
    }
    return _razorpay!;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TableSessionResponse? _sessionResponse;
  TableSessionResponse? get sessionResponse => _sessionResponse;

  Function(bool success, String message)? _onExtensionPaymentCompleted;

  Future<bool> startTableSession(
    String tableId, {
    List<String>? chairIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = TableSessionRequest(tableId: tableId, chairIds: chairIds);
      _sessionResponse = await _scanRepository.createTableSession(request);

      if (_sessionResponse?.success == true) {
        return true;
      } else {
        _errorMessage = _sessionResponse?.message ?? 'Failed to start session.';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LeaveTableSessionResult> leaveTableSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _scanRepository.leaveTableSession();
      if (result.success) {
        _sessionResponse = null;
      } else {
        _errorMessage = result.message;
      }
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return LeaveTableSessionResult(success: false, message: e.message);
    } catch (e) {
      _errorMessage = 'Failed to end table session.';
      return LeaveTableSessionResult(
        success: false,
        message: 'Failed to end table session.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TableOccupiedDetails> fetchOccupiedChairsDetails(
    String tableId,
  ) async {
    try {
      return await _scanRepository.getOccupiedChairsDetails(tableId);
    } catch (_) {
      return TableOccupiedDetails(maxCapacity: 4, occupiedChairs: []);
    }
  }

  Future<List<String>> fetchOccupiedChairs(String tableId) async {
    try {
      return await _scanRepository.getOccupiedChairs(tableId);
    } catch (_) {
      return [];
    }
  }

  void clearSession() {
    _sessionResponse = null;
    notifyListeners();
  }

  /// Fetches the current active session from the server and updates state.
  /// Call this whenever the Menu screen loads or after placing a food order,
  /// so CanteenFlowGuideCard shows the correct timer / green card.
  Future<void> refreshSession() async {
    try {
      final response = await _scanRepository.fetchActiveSession();
      if (response == null) {
        return;
      }
      _sessionResponse = response;
      notifyListeners();
    } catch (_) {
      // Silent — don't break the UI if the session fetch fails
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<ExtendSessionResult> extendTableSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _scanRepository.extendTableSession();
      if (result.success) {
        await refreshSession();
      } else {
        _errorMessage = result.message;
      }
      return result;
    } catch (_) {
      _errorMessage = 'Failed to extend table session.';
      return ExtendSessionResult(
        success: false,
        message: 'Failed to extend table session.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Launches Razorpay Payment Gateway SDK for paid session extensions (+15 mins)
  Future<void> initiatePaidSessionExtension({
    required double fee,
    required Function(bool success, String message) onCompleted,
  }) async {
    _onExtensionPaymentCompleted = onCompleted;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final key = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    if (key.isEmpty || key == 'rzp_test_your_key_here') {
      final res = await extendTableSession();
      _isLoading = false;
      notifyListeners();
      onCompleted(res.success, res.message);
      return;
    }

    var options = {
      'key': key,
      'amount': (fee * 100).toInt(),
      'name': 'Quick Plate',
      'description': '15-Min Meal Session Extension Fee',
      'timeout': 300,
      'prefill': {'contact': '', 'email': ''},
    };

    try {
      _isLoading = false;
      notifyListeners();
      razorpay.open(options);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onCompleted(false, 'Could not open Razorpay payment gateway: $e');
    }
  }

  void _handleRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _scanRepository.extendTableSession();
      if (res.success) {
        await refreshSession();
      } else {
        _errorMessage = res.message;
      }
      _onExtensionPaymentCompleted?.call(
        res.success,
        res.success
            ? 'Razorpay Payment Successful (ID: ${response.paymentId}). ${res.message}'
            : res.message,
      );
    } catch (e) {
      _onExtensionPaymentCompleted?.call(
        false,
        'Payment succeeded but failed to update session on server.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleRazorpayPaymentError(PaymentFailureResponse response) {
    _onExtensionPaymentCompleted?.call(
      false,
      response.message ?? 'Razorpay Payment Failed or Cancelled',
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    _onExtensionPaymentCompleted?.call(
      false,
      'External wallet selected (${response.walletName})',
    );
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }
}
