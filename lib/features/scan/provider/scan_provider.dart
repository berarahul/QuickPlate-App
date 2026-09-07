import 'package:flutter/material.dart';
import '../model/table_session_request.dart';
import '../model/table_session_response.dart';
import '../repository/scan_repository.dart';
import '../../../core/network/api_exceptions.dart';

class ScanProvider extends ChangeNotifier {
  final ScanRepository _scanRepository;

  ScanProvider(this._scanRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TableSessionResponse? _sessionResponse;
  TableSessionResponse? get sessionResponse => _sessionResponse;

  Future<bool> startTableSession(String tableId, {List<String>? chairIds}) async {
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

  Future<TableOccupiedDetails> fetchOccupiedChairsDetails(String tableId) async {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
