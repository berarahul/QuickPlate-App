import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import 'core/app_exports.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/repository/auth_repository.dart';

void main() {
  // Setup DI manually before app start
  final networkInfo = NetworkInfoImpl(Connectivity());
  final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
  final authRepository = AuthRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider(networkInfo)),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Plate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splashScreen,
      routes: AppRoutes.routes,
    );
  }
}
