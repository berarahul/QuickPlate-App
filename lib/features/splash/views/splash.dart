import '../../../core/app_exports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Hold splash screen then navigate
    await Future.delayed(const Duration(seconds: 2));

    final authToken = await SharedPrefsHelper.getAuthToken();
    final isRegistered = await SharedPrefsHelper.getIsRegistered();
    final hasSeenOnboarding = await SharedPrefsHelper.getHasSeenOnboarding();

    if (mounted) {
      if (authToken != null && authToken.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardScreen);
      } else if (isRegistered) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
      } else if (hasSeenOnboarding) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.studentRegistrationScreen);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboardingScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text(AppStrings.appName, style: AppTextStyles.splashTitle),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
