import 'package:flutter/material.dart';

// --- 🚀 Refactored Imports ---
// These files must be renamed in your 'screens' folder
import 'screens/splash_screen.dart';
import 'screens/athlete_login_signup_screen.dart'; // Was login_signup_screen
import 'screens/athlete_dashboard_screen.dart'; // Was child_dashboard_screen
import 'screens/coach_login_screen.dart'; // Was parent_login_screen
import 'screens/training_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/coach_dashboard_screen.dart'; // Was parent_dashboard_screen
import 'screens/coach_athlete_detail_screen.dart'; // Was parent_child_detail_screen
import 'screens/coach_registration_screen.dart'; // Was parent_registration_screen
import 'screens/coach_notifications_screen.dart'; // Was parent_notifications_screen
import 'screens/drill_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoachFitnessApp());
}

class CoachFitnessApp extends StatelessWidget {
  const CoachFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 🎨 New Black & Cyan Theme (Corrected) ---
    const Color primaryCyan = Color(0xFF00BCD4); // Our main cyan color
    const Color darkBackground = Color(0xFF121212); // A standard dark mode background
    const Color darkSurface = Color(0xFF1E1E1E); // For cards, appbars, etc.

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
        onPrimary: Colors.black, // Text on top of cyan buttons
        secondary: primaryCyan,
        onSecondary: Colors.black,
        onSurface: Colors.white, // Default text color
      ),

      // --- Custom UI Themes ---

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white, // This is for icons
        elevation: 0, // No shadow
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          color: Colors.white, // ⭐️ This makes the title white
        ),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.black, // Text on buttons
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
      ), // ⭐️ Correct comma is here

      // Card Theme
      cardTheme: CardThemeData( // ⭐️ No space here
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ), // ⭐️ Correct comma is here

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryCyan,
        unselectedItemColor: Colors.grey,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.black,
      ),
    );

    return MaterialApp(
      title: 'CoachFitness',
      debugShowCheckedModeBanner: false,
      theme: darkTheme, // Set the light theme (if you have one)
      darkTheme: darkTheme, // Set the dark theme
      themeMode: ThemeMode.dark, // Force dark mode

      // --- 🚀 Refactored Navigation Routes ---
      initialRoute: '/',
      routes: {
        // Athlete Flow
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AthleteLoginSignupScreen(), // For Athletes
        '/training': (context) => const TrainingScreen(),
        '/avatar': (context) => const AvatarScreen(),
        '/rewards': (context) => const RewardsScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/settings': (context) => const SettingsScreen(),

        // Coach Flow
        '/coach-login': (context) => const CoachLoginScreen(),
        '/coach-home': (context) => const CoachDashboardScreen(),
        '/coach-registration': (context) => const CoachRegistrationScreen(),
        '/coach-notifications': (context) => const CoachNotificationsScreen(),
      },
      // Using onGenerateRoute to handle passing arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/coach-athlete-detail') {
          // Coach Detail screen for a specific athlete
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              // Pass 'athleteData' instead of 'childData'
              return CoachAthleteDetailScreen(athleteData: args);
            },
          );
        } else if (settings.name == '/athlete-home') {
          // Athlete Dashboard screen
          final athleteName = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) {
              // Pass 'athleteName' and default to 'Athlete'
              return AthleteDashboardScreen(
                  athleteName: athleteName ?? 'Athlete');
            },
          );
        } else if (settings.name == '/drill-detail') {
          // Drill Detail Screen (no change needed here)
          final drillData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return DrillDetailScreen(drillData: drillData);
            },
          );
        }
        return null; // Let the default routing handle other paths
      },
    );
  }
}