import '../../../core/app_exports.dart';
import '../model/onboarding_model.dart';
import '../../../core/utils/shared_prefs_helper.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final PageController pageController = PageController();

  final List<OnboardingModel> onboardingData = [
    OnboardingModel(
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      imageUrl: ImageConstant.onboarding1,
    ),
    OnboardingModel(
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      imageUrl: ImageConstant.onboarding2,
    ),
    OnboardingModel(
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      imageUrl: ImageConstant.onboarding3,
    ),
  ];

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
    // Remember if they reached the last screen
    if (index == onboardingData.length - 1) {
      SharedPrefsHelper.setHasSeenOnboarding(true);
    }
  }

  void skipToLastPage() {
    pageController.animateToPage(
      onboardingData.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
