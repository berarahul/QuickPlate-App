import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/auth_repository.dart';
import '../model/student_registration_request.dart';
import '../model/student_registration_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../../core/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  String? _userName;
  String? get userName => _userName ?? _loginResponse?.data?.user?.name;

  String? _userEmail;
  String? get userEmail => _userEmail ?? _loginResponse?.data?.user?.email;

  AuthProvider(this._authRepository) {
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    _userName = await SharedPrefsHelper.getUserName();
    _userEmail = await SharedPrefsHelper.getUserEmail();
    _authToken = await SharedPrefsHelper.getAuthToken();
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StudentRegistrationResponse? _registrationResponse;
  StudentRegistrationResponse? get registrationResponse =>
      _registrationResponse;

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
          final user = _loginResponse?.data?.user;
          if (user != null) {
            await SharedPrefsHelper.setUserName(user.name);
            await SharedPrefsHelper.setUserEmail(user.email);
            _userName = user.name;
            _userEmail = user.email;
          }
          // FIX #4: Sync FCM token to backend right after login.
          // initNotifications() runs at startup before the user is logged in,
          // so the backend never has a valid auth header during the initial sync.
          // Calling syncToken() here ensures the token is registered with a
          // valid Bearer token in the Authorization header.
          await NotificationService.instance.syncToken();
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

  Future<void> logout() async {
    _authToken = null;
    _loginResponse = null;
    _userName = null;
    _userEmail = null;

    try {
      // Unregister token first (needs the auth header/token that is currently active)
      await NotificationService.instance.unregisterToken();
    } catch (e) {
      debugPrint("Error during FCM token unregistration: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('fcm_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    notifyListeners();
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
