import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import the new ViewModel
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
    // 1. Listen for the *first* authentication state change
    _viewModel.authStateChanges.listen((User? user) {
      // 2. Only navigate if the widget is mounted and we haven't gone anywhere
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        // 3. Get the correct route from the ViewModel
        final route = _viewModel.getInitialRoute(user);
        
        // 4. Navigate and clear the navigation stack
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 100,
              color: theme.colorScheme.primary,
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
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Checking login status...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}