import '../../../core/app_exports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 56,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppStrings.appName, style: AppTextStyles.splashTitle),
                const SizedBox(height: 8),
                Text(
                  'Campus canteen, simplified.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
