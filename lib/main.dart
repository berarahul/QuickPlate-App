import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/app_exports.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/scan/provider/scan_provider.dart';
import 'features/scan/repository/scan_repository.dart';
import 'features/menu/provider/menu_provider.dart';
import 'features/menu/repository/menu_repository.dart';
import 'features/cart/provider/order_provider.dart';
import 'features/cart/repository/order_repository.dart';
import 'features/cart/provider/cart_provider.dart';
import 'features/cart/repository/cart_repository.dart';
import 'features/notifications/provider/notification_provider.dart';
import 'features/notifications/repository/notification_repository.dart';
import 'core/services/notification_service.dart';

// FIX #2: The background handler MUST be a top-level function registered here
// in main.dart, BEFORE runApp() is called. This is required by firebase_messaging
// so the native Android/iOS layer can spawn a headless Dart isolate to run it
// when the app is in the background or terminated.
// We re-export the function defined in notification_service.dart here.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX #2: Register background handler as the very first thing, before
  // Firebase.initializeApp() or runApp(). The OS needs to know about this
  // handler at the earliest possible moment during app startup.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: ".env");

  // Setup DI manually before app start
  final networkInfo = NetworkInfoImpl(Connectivity());
  final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
  final authRepository = AuthRepository(apiClient);
  final scanRepository = ScanRepository(apiClient);
  final menuRepository = MenuRepository(apiClient);
  final orderRepository = OrderRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  final cartRepository = CartRepository(apiClient);

  // FIX #3: Added `await` here. Without await, runApp() fires immediately while
  // initNotifications is still running, causing a race condition where
  // getInitialMessage() (for terminated-state taps) fires too early and is lost.
  await NotificationService.instance.initNotifications(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider(networkInfo)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => ScanProvider(scanRepository)),
        ChangeNotifierProvider(create: (_) => MenuProvider(menuRepository)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Quick Plate',
          navigatorKey: AppRoutes.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
