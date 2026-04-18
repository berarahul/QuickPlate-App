import 'package:flutter/material.dart';
import '../repository/auth_repository.dart';
import '../model/student_registration_request.dart';
import '../model/student_registration_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/utils/shared_prefs_helper.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StudentRegistrationResponse? _registrationResponse;
  StudentRegistrationResponse? get registrationResponse => _registrationResponse;

  LoginResponse? _loginResponse;
  LoginResponse? get loginResponse => _loginResponse;

  String? _authToken;
  String? get authToken => _authToken;

  Future<bool> registerStudent(StudentRegistrationRequest request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _registrationResponse = await _authRepository.registerStudent(request);

      // If success is true, we consider it a success
      if (_registrationResponse?.success == true) {
        await SharedPrefsHelper.setIsRegistered(true);
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

  Future<bool> login(LoginRequest request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _loginResponse = await _authRepository.login(request);

      if (_loginResponse?.success == true) {
        _authToken = _loginResponse?.data?.token;
        if (_authToken != null) {
          await SharedPrefsHelper.setAuthToken(_authToken!);
        }
        return true;
      } else {
        _errorMessage = _loginResponse?.message ?? 'Login failed';
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
