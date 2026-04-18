import 'package:flutter/material.dart';
import '../repository/auth_repository.dart';
import '../model/student_registration_request.dart';
import '../model/student_registration_response.dart';
import '../../../core/network/api_exceptions.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StudentRegistrationResponse? _registrationResponse;
  StudentRegistrationResponse? get registrationResponse => _registrationResponse;

  Future<bool> registerStudent(StudentRegistrationRequest request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _registrationResponse = await _authRepository.registerStudent(request);
      
      // If success is true, we consider it a success
      if (_registrationResponse?.success == true) {
        return true;
      } else {
        _errorMessage = _registrationResponse?.message ?? 'Registration failed';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
