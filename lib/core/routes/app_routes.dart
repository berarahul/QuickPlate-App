import 'package:flutter/material.dart';
import '../../features/splash/views/splash.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/auth/views/student_registration.dart';
import '../../features/auth/views/student_login.dart';
import '../../features/auth/views/forgot_password_view.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/menu/views/menu_screen.dart';
import '../../features/cart/views/order_history_screen.dart';
import '../../features/notifications/views/notification_screen.dart';
import '../../features/table_reservation/views/table_reservation_screen.dart';
import '../../features/table_reservation/views/my_reservations_screen.dart';

import '../../features/scan/views/scan_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splashScreen = '/splash';
  static const String onboardingScreen = '/onboarding';

  // Future auth and home routes
  static const String loginScreen = '/login';
  static const String studentRegistrationScreen = '/student_registration';
  static const String forgotPasswordScreen = '/forgot_password';
  static const String dashboardScreen = '/dashboard';
  static const String menuScreen = '/menu';
  static const String scanScreen = '/scan';
  static const String orderHistoryScreen = '/order_history';
  static const String notificationScreen = '/notifications';
  static const String tableReservationScreen = '/table_reservation';
  static const String myReservationsScreen = '/my_reservations';

  static Map<String, WidgetBuilder> get routes => {
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    studentRegistrationScreen: (context) => const StudentRegistration(),
    loginScreen: (context) => const StudentLogin(),
    forgotPasswordScreen: (context) => const ForgotPasswordView(),
    dashboardScreen: (context) => const DashboardScreen(),
    menuScreen: (context) => const MenuScreen(),
    scanScreen: (context) => const ScanScreen(isActive: true),
    orderHistoryScreen: (context) => const OrderHistoryScreen(),
    notificationScreen: (context) => const NotificationScreen(),
    tableReservationScreen: (context) => const TableReservationScreen(),
    myReservationsScreen: (context) => const MyReservationsScreen(),
  };
}
