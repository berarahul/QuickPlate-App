import 'package:flutter/material.dart';

/// Allows child screens (e.g. MenuScreen) embedded in Dashboard's
/// IndexedStack to request a tab change — for example, tapping the
/// cart icon in the menu header should switch to the Cart tab.
class DashboardTabController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void switchTo(int tab) {
    if (tab != _index) {
      _index = tab;
      notifyListeners();
    }
  }
}
