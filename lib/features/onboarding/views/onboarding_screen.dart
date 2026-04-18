import '../../../core/app_exports.dart';
import '../provider/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late OnboardingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = OnboardingProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, child) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_provider.currentIndex < _provider.onboardingData.length - 1)
                      TextButton(
                        onPressed: _provider.skipToLastPage,
                        child: const Text(AppStrings.skip, style: AppTextStyles.textButton),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _provider.pageController,
                    onPageChanged: _provider.onPageChanged,
                    itemCount: _provider.onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = _provider.onboardingData[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood_rounded, size: 150, color: AppColors.primaryLight),
                          const SizedBox(height: 40),
                          Text(data.title, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              data.description,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _provider.onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 10,
                            width: _provider.currentIndex == index ? 24 : 10,
                            decoration: BoxDecoration(
                              color: _provider.currentIndex == index
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      CustomElevatedButton(
                        text: _provider.currentIndex == _provider.onboardingData.length - 1
                            ? AppStrings.getStarted
                            : AppStrings.next,
                        onPressed: () {
                          if (_provider.currentIndex == _provider.onboardingData.length - 1) {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.studentRegistrationScreen,
                            );
                          } else {
                            _provider.nextPage();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
