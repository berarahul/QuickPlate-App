import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_info.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkInfo _networkInfo;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Add optional callback when app comes back online to refresh data globally
  VoidCallback? onBackOnline;

  NetworkProvider(this._networkInfo) {
    _initConnectionStatus();
  }

  void _initConnectionStatus() async {
    _isOffline = !(await _networkInfo.isConnected);
    notifyListeners();

    _networkInfo.onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);

      // Look for a transition from offline -> online
      if (_isOffline && !offline) {
        if (onBackOnline != null) onBackOnline!();
      }

      if (_isOffline != offline) {
        _isOffline = offline;
        notifyListeners();
      }
    });
  }
}
