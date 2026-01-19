import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package
import '../viewmodel/splash_viewmodel.dart';

/*
  VIEW (V)
  This is the splash screen. Its sole purpose is to check the auth state
  and redirect the user immediately upon loading.
*/
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final _viewModel = SplashViewModel();
  
  // Flag to ensure navigation happens only once
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Initialize the view model (loads session service)
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Initialize the view model's auth repository and session service
      await _viewModel.init();

      // 1. Listen for the *first* authentication state change
      _viewModel.authStateChanges.listen((User? user) async {
        // 2. Only navigate if the widget is mounted and we haven't gone anywhere
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          // 3. Get the correct route from the ViewModel
          final route = await _viewModel.getInitialRoute(user);
          
          // 4. Navigate with arguments if it's an athlete session recovery
          if (route == '/athlete-home') {
            final athleteData = await _viewModel.getSavedAthleteData();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(
                route,
                arguments: athleteData,
              );
            }
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          }
        }
      });
    } catch (e) {
      // If there's an error, go to role selection
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    }
  }

  @override
  void dispose() {
    // No explicit dispose needed for Stream.listen unless stored as a Subscription
    super.dispose();
  }

  // 5. Build method: Simple static screen while waiting for the check
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // REPLACED ICON WITH LOTTIE ANIMATION
            SizedBox(
              height: 250,
              width: 250,
              child: Lottie.asset(
                'assets/animations/splash_running.json',
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'CoachFitness',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Minimal loading indicator
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              'Checking login status...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}