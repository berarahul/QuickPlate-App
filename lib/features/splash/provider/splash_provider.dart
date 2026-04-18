import 'package:flutter/material.dart';
import '../repository/splash_repository.dart';

class SplashProvider extends ChangeNotifier {
  final SplashRepository repository;

  SplashProvider(this.repository);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initializeApp() async {
    // Perform initial API calls or local checks using the repository
    await repository.checkAppStatus();
    _isInitialized = true;
    notifyListeners();
  }
}
