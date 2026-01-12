import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// Import the new ViewModel
import '../viewmodel/splash_viewmodel.dart';

/*
  VIEW (V)
  Refactored Splash View with:
  - Gradient Backgrounds
  - Text Shadows & Typography improvements
  - Fade-in animations
  - Soft glows behind the animation
*/
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  final _viewModel = SplashViewModel();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup a simple fade-in effect for the text elements
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    );

    // Start animation
    _fadeController.forward();

    // Sign out and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get the initial route (signs out user first)
    final route = await _viewModel.getInitialRoute();

    // Navigate if widget is still mounted
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      // We use a Container here to provide the gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // Use theme colors but with slight variation for depth
              colorScheme.surface,
              // If you have a surfaceContainerHighest, use it, else mix primary with white/black
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.05) ?? Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The Animation with a "Glow" effect behind it
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Lottie.network(
                  'https://lottie.host/1f8628ae-3cec-43be-b8d9-ac2835479081/xMZnA2zc9O.json',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  // Add a fallback in case internet is spotty
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.fitness_center_rounded, 
                      size: 150, 
                      color: colorScheme.primary.withOpacity(0.5)
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 2. Animated Text Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'CoachFitness',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900, // Extra bold for impact
                        color: colorScheme.primary,
                        letterSpacing: 1.2, // Adds a modern feel
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Train Smarter, Play Harder',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 3. Subtle loading indicator instead of plain text
                    SizedBox(
                      height: 20, 
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}