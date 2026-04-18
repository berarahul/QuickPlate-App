import 'package:flutter/material.dart';
import '../model/menu_response.dart';
import '../repository/menu_repository.dart';
import '../../../core/network/api_exceptions.dart';

class MenuProvider extends ChangeNotifier {
  final MenuRepository _menuRepository;

  MenuProvider(this._menuRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MenuItem> _menuItems = [];
  List<MenuItem> get menuItems => _menuItems;

  Future<void> fetchMenu() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _menuRepository.getMenu();

      if (response.success == true && response.data != null) {
        _menuItems = response.data!;
      } else {
        _errorMessage = response.message ?? 'Failed to load menu.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void retryFetchMenu() {
    fetchMenu();
  }
}
