import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel for the Onboarding flow.
///
/// Manages the PageController, tracks current page index,
/// and persists onboarding completion status to SharedPreferences.
class OnboardingViewModel extends ChangeNotifier {
  // Constants
  static const String _onboardingCompleteKey = 'onboardingComplete';
  static const int totalPages = 3;

  // PageController for the onboarding PageView
  final PageController pageController = PageController();

  // Current page index (0-indexed)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  /// Whether we're on the last page
  bool get isLastPage => _currentPage == totalPages - 1;

  /// Updates the current page index when the user swipes
  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  /// Advances to the next page or completes onboarding if on the last page
  Future<void> nextPage(BuildContext context) async {
    if (isLastPage) {
      await completeOnboarding(context);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Skips the onboarding and navigates directly to role selection
  Future<void> skip(BuildContext context) async {
    await completeOnboarding(context);
  }

  /// Marks onboarding as complete and navigates to role selection
  Future<void> completeOnboarding(BuildContext context) async {
    // Save completion status to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);

    // Navigate to role selection, replacing the current route
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/role-selection');
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

/// Data model for an onboarding slide
class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Predefined onboarding slides content
const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    icon: Icons.sports,
    title: 'Connect with Coaches',
    description:
        'Find expert coaches to elevate your game and unlock your full potential.',
  ),
  OnboardingSlide(
    icon: Icons.trending_up,
    title: 'Track Your Progress',
    description:
        'Monitor your drills, stats, and improvements with detailed analytics.',
  ),
  OnboardingSlide(
    icon: Icons.emoji_events,
    title: 'Achieve Your Goals',
    description:
        'Reach new heights with personalized training plans designed for you.',
  ),
];
