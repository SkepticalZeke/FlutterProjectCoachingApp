import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ⭐️ MOVED TO lib/ ⭐️

// --- Screen Imports Updated to new MVVM structure ---
import 'src/features/0_auth/view/splash_view.dart';
import 'src/features/0_auth/view/role_selection_view.dart';
import 'src/features/0_auth/view/athlete_login_view.dart';
import 'src/features/2_athlete_flow/view/athlete_dashboard_view.dart';
import 'src/features/0_auth/view/coach_login_view.dart';
import 'src/features/2_athlete_flow/view/training_view.dart';
import 'src/features/2_athlete_flow/view/avatar_view.dart';
import 'src/features/2_athlete_flow/view/rewards_view.dart';
import 'src/features/2_athlete_flow/view/progress_view.dart';
import 'src/features/2_athlete_flow/view/settings_view.dart';
import 'src/features/1_coach_flow/view/coach_dashboard_view.dart';
import 'src/features/1_coach_flow/view/coach_athlete_detail_view.dart';
import 'src/features/0_auth/view/coach_registration_view.dart';
import 'src/features/1_coach_flow/view/coach_notifications_view.dart';
import 'src/features/2_athlete_flow/view/drill_detail_view.dart';
import 'src/features/1_coach_flow/view/create_drill_view.dart';
import 'src/features/1_coach_flow/view/assign_drill_view.dart';
import 'src/features/1_coach_flow/view/review_submission_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: PlatformSwitch.currentPlatform,
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
      themeMode: ThemeMode.dark, // Force dark mode
      initialRoute: '/',
      // --- Routes ---
      routes: {
        // General Flow (from 0_auth)
        '/': (context) => const SplashView(),
        '/role-selection': (context) => const RoleSelectionView(),
        '/login': (context) => const AthleteLoginView(),

        // Coach Flow (from 0_auth and 1_coach_flow)
        '/coach-login': (context) => const CoachLoginView(),
        '/coach-home': (context) => const CoachDashboardView(),
        '/coach-registration': (context) => const CoachRegistrationView(),
        '/coach-notifications': (context) => const CoachNotificationsView(),
        '/create-drill': (context) => const CreateDrillView(),
      },
      // --- onGenerateRoute for passing arguments ---
      onGenerateRoute: (settings) {
        // Coach Detail Screen
        if (settings.name == '/coach-athlete-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return CoachAthleteDetailView(athleteData: args);
            },
          );
        }
        // Athlete Home Screen
        if (settings.name == '/athlete-home') {
          final athleteData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return AthleteDashboardView(athleteData: athleteData);
            },
          );
        }
        // Drill Detail Screen
        if (settings.name == '/drill-detail') {
          final routeArgs = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return DrillDetailView(routeArgs: routeArgs);
            },
          );
        }
        // Assign Drill Screen
        if (settings.name == '/assign-drill') {
          final athleteData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AssignDrillView(athleteData: athleteData),
          );
        }
        // Review Submission Screen
        if (settings.name == '/review-submission') {
          final routeArgs = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) =>
                ReviewSubmissionView(routeArgs: routeArgs),
          );
        }

        // --- Navigation for Athlete Bottom Nav Bar ---
        final athleteData = settings.arguments as Map<String, dynamic>? ?? {};

        if (settings.name == '/training') {
          return MaterialPageRoute(
            builder: (context) =>
                TrainingView(athleteData: athleteData),
          );
        }
        if (settings.name == '/avatar') {
          return MaterialPageRoute(
            builder: (context) =>
                AvatarView(athleteData: athleteData),
          );
        }
        if (settings.name == '/rewards') {
          return MaterialPageRoute(
            builder: (context) =>
                RewardsView(athleteData: athleteData),
          );
        }
        if (settings.name == '/progress') {
          return MaterialPageRoute(
            builder: (context) =>
                ProgressView(athleteData: athleteData),
          );
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute(
            builder: (context) =>
                SettingsView(athleteData: athleteData),
          );
        }

        return null; // Handle unknown routes
      },
    );
  }
}