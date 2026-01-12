import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// Import the new ViewModel
import '../viewmodel/splash_viewmodel.dart';

/*
  VIEW (V)
  This is the splash screen. Its sole purpose is to sign out any existing
  session and redirect the user to role selection.
*/
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final _viewModel = SplashViewModel();

  @override
  void initState() {
    super.initState();
    // Sign out and navigate to role selection
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
            // Lottie animation
            Lottie.network(
              'https://lottie.host/1f8628ae-3cec-43be-b8d9-ac2835479081/xMZnA2zc9O.json',
              width: 300,
              height: 300,
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
            const SizedBox(height: 10),
            Text(
              'Loading...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}