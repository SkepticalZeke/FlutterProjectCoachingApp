import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate after a delay to simulate loading/splash screen
    Future.delayed(const Duration(seconds: 3), () {
      // In a real app, this would check auth status and navigate accordingly.
      Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 120, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'GoalBuddy', // Updated App Name
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.green[800],
              ),
            ),
            // New Tagline
            const Text(
              'Football Fun for Every Young Champion!', 
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.amber),
          ],
        ),
      ),
    );
  }
}