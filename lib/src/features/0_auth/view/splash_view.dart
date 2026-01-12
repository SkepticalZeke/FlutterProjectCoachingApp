import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
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
  // Track when the splash screen started
  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    // 1. Listen for the *first* authentication state change
    _viewModel.authStateChanges.listen((User? user) async {
      // 2. Only navigate if the widget is mounted and we haven't gone anywhere
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;

        // 3. Calculate remaining time to show splash (minimum 5 seconds)
        final elapsedTime = DateTime.now().difference(_splashStartTime!);
        const minSplashDuration = Duration(seconds: 5);

        if (elapsedTime < minSplashDuration) {
          await Future.delayed(minSplashDuration - elapsedTime);
        }

        // 4. Get the correct route from the ViewModel
        final route = _viewModel.getInitialRoute(user);

        // 5. Navigate and clear the navigation stack
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(route);
        }
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
            // Lottie Animation
            Lottie.network(
              'https://lottie.host/1f8628ae-3cec-43be-b8d9-ac2835479081/xMZnA2zc9O.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
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