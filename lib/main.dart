import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Model/firebase_options.dart'; // Using your Model/ folder path

// --- Screen Imports Updated to 'View' folder ---
import 'View/splash_screen.dart';
import 'View/athlete_login_signup_screen.dart';
import 'View/athlete_dashboard_screen.dart';
import 'View/coach_login_screen.dart';
import 'View/training_screen.dart';
import 'View/avatar_screen.dart';
import 'View/rewards_screen.dart';
import 'View/progress_screen.dart';
import 'View/settings_screen.dart';
import 'View/coach_dashboard_screen.dart';
import 'View/coach_athlete_detail_screen.dart';
import 'View/coach_registration_screen.dart';
import 'View/coach_notifications_screen.dart';
import 'View/drill_detail_screen.dart';
import 'View/create_drill_screen.dart';
import 'View/assign_drill_screen.dart'; 
import 'View/review_submission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CoachFitnessApp());
}

class CoachFitnessApp extends StatelessWidget {
  const CoachFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Theme Data ---
    const Color primaryCyan = Color(0xFF00BCD4);
    const Color darkBackground = Color(0xFF121212);
    const Color darkSurface = Color(0xFF1E1E1E);

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCyan,
        brightness: Brightness.dark,
        surface: darkSurface,
        primary: primaryCyan,
        onPrimary: Colors.black,
        secondary: primaryCyan,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      // Using CardTheme, not CardThemeData (modern syntax)
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryCyan,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.black,
      ),
    );

    return MaterialApp(
      title: 'CoachFitness',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      // --- Routes ---
      routes: {
        // General Flow
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AthleteLoginSignupScreen(),

        // Coach Flow
        '/coach-login': (context) => const CoachLoginScreen(),
        '/coach-home': (context) => const CoachDashboardScreen(),
        '/coach-registration': (context) => const CoachRegistrationScreen(),
        '/coach-notifications': (context) => const CoachNotificationsScreen(),
        '/create-drill': (context) => const CreateDrillScreen(),
      },
      // --- onGenerateRoute for passing arguments ---
      onGenerateRoute: (settings) {
        // Coach Detail Screen
        if (settings.name == '/coach-athlete-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return CoachAthleteDetailScreen(athleteData: args);
            },
          );
        }
        // Athlete Home Screen
        if (settings.name == '/athlete-home') {
          final athleteData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return AthleteDashboardScreen(athleteData: athleteData);
            },
          );
        }
        // Drill Detail Screen
        if (settings.name == '/drill-detail') {
          final routeArgs = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return DrillDetailScreen(routeArgs: routeArgs);
            },
          );
        }
        
        // ⭐️ ADDED THIS ROUTE ⭐️
        // Assign Drill Screen
        if (settings.name == '/assign-drill') {
          final athleteData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AssignDrillScreen(athleteData: athleteData),
          );
        }

        // --- Navigation for Athlete Bottom Nav Bar ---
        final athleteData = settings.arguments as Map<String, dynamic>? ?? {};

        if (settings.name == '/training') {
          return MaterialPageRoute(
            builder: (context) =>
                const TrainingScreen(), // Note: TrainingScreen doesn't need data yet
          );
        }
        if (settings.name == '/avatar') {
          return MaterialPageRoute(
            builder: (context) => AvatarScreen(athleteData: athleteData),
          );
        }
        if (settings.name == '/rewards') {
          return MaterialPageRoute(
            builder: (context) => RewardsScreen(athleteData: athleteData),
          );
        }
        if (settings.name == '/progress') {
          return MaterialPageRoute(
            builder: (context) => ProgressScreen(athleteData: athleteData),
          );
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute(
            builder: (context) => SettingsScreen(athleteData: athleteData),
          );
        }
        if (settings.name == '/review-submission') {
          final routeArgs = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) =>
                ReviewSubmissionScreen(routeArgs: routeArgs),
          );
        }

        return null; // Handle unknown routes
      },
    );
  }
}