import 'package:flutter/material.dart';
import '../../features/splash/views/splash.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/auth/views/student_registration.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String onboardingScreen = '/onboarding';

  // Future auth and home routes
  static const String loginScreen = '/login';
  static const String studentRegistrationScreen = '/student_registration';
  static const String homeScreen = '/home';

  static Map<String, WidgetBuilder> get routes => {
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    studentRegistrationScreen: (context) => const StudentRegistration(),
  };
}
