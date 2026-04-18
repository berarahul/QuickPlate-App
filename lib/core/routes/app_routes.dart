import 'package:flutter/material.dart';
import '../../features/splash/views/splash.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/auth/views/student_registration.dart';
import '../../features/auth/views/student_login.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/menu/views/menu_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String onboardingScreen = '/onboarding';

  // Future auth and home routes
  static const String loginScreen = '/login';
  static const String studentRegistrationScreen = '/student_registration';
  static const String dashboardScreen = '/dashboard';
  static const String menuScreen = '/menu';

  static Map<String, WidgetBuilder> get routes => {
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    studentRegistrationScreen: (context) => const StudentRegistration(),
    loginScreen: (context) => const StudentLogin(),
    dashboardScreen: (context) => const DashboardScreen(),
    menuScreen: (context) => const MenuScreen(),
  };
}
