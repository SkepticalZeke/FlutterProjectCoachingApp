import 'package:flutter/material.dart';
import '../viewmodel/onboarding_viewmodel.dart';

/// Onboarding screen with a 3-slide PageView.
///
/// Shows an introduction to the app's features and allows
/// users to skip or navigate through the slides.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final OnboardingViewModel _viewModel = OnboardingViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color backgroundColor = Color(0xFF121212);
    const Color surfaceColor = Color(0xFF1E1E1E);
    const Color primaryCyan = Color(0xFF00BCD4);
    const Color inactiveGrey = Color(0xFF666666);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              children: [
                // Skip button at top right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => _viewModel.skip(context),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView with slides
                Expanded(
                  child: PageView.builder(
                    controller: _viewModel.pageController,
                    onPageChanged: _viewModel.onPageChanged,
                    itemCount: onboardingSlides.length,
                    itemBuilder: (context, index) {
                      final slide = onboardingSlides[index];
                      return _OnboardingSlideWidget(
                        slide: slide,
                        surfaceColor: surfaceColor,
                        primaryColor: primaryCyan,
                      );
                    },
                  ),
                ),

                // Bottom navigation area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left spacer (for symmetry)
                      const SizedBox(width: 80),

                      // Dot indicators (center)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingSlides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _viewModel.currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _viewModel.currentPage == index
                                  ? primaryCyan
                                  : inactiveGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next/Get Started button (right)
                      SizedBox(
                        width: 80,
                        child: TextButton(
                          onPressed: () => _viewModel.nextPage(context),
                          child: Text(
                            _viewModel.isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              color: primaryCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
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

/// Widget for a single onboarding slide
class _OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;
  final Color surfaceColor;
  final Color primaryColor;

  const _OnboardingSlideWidget({
    required this.slide,
    required this.surfaceColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                slide.icon,
                size: 80,
                color: primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              fontFamily: 'Inter',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
