import '../../../core/app_exports.dart';
import '../provider/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late OnboardingProvider _provider;

  // Distinct icon per step (illustration stand-in).
  static const _icons = <IconData>[
    Icons.restaurant_menu_rounded,
    Icons.delivery_dining_rounded,
    Icons.payments_rounded,
  ];

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
          builder: (_, child) {
            final isLast =
                _provider.currentIndex == _provider.onboardingData.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress pips
                      Row(
                        children: List.generate(
                          _provider.onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: _provider.currentIndex == index ? 28 : 6,
                            decoration: BoxDecoration(
                              color: _provider.currentIndex == index
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        TextButton(
                          onPressed: _provider.skipToLastPage,
                          child: const Text(AppStrings.skip),
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _provider.pageController,
                    onPageChanged: _provider.onPageChanged,
                    itemCount: _provider.onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = _provider.onboardingData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 168,
                              height: 168,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _icons[index],
                                  size: 56,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(data.title, style: AppTextStyles.displayLarge),
                            const SizedBox(height: 16),
                            Text(
                              data.description,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: CustomElevatedButton(
                    text: isLast ? AppStrings.getStarted : AppStrings.next,
                    leading: isLast
                        ? const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: AppColors.white,
                          )
                        : null,
                    onPressed: () async {
                      if (isLast) {
                        await SharedPrefsHelper.setHasSeenOnboarding(true);
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.studentRegistrationScreen,
                        );
                      } else {
                        _provider.nextPage();
                      }
                    },
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
