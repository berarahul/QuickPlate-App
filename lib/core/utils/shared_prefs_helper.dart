import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyIsRegistered = 'is_registered';
  static const String _keyAuthToken = 'auth_token';

  static Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, value);
  }

  static Future<bool> getIsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsRegistered) ?? false;
  }

  static Future<void> setIsRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRegistered, value);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
  }
}
