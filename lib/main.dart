import 'package:flutter/material.dart';
//testing commit
import 'screens/splash_screen.dart';
import 'screens/login_signup_screen.dart';
import 'screens/child_dashboard_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/training_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/parent_dashboard_screen.dart';
import 'screens/parent_child_detail_screen.dart';
import 'screens/parent_registration_screen.dart'; 
import 'screens/parent_notifications_screen.dart';
import 'screens/drill_detail_screen.dart'; 

void main() {
  
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FootballSkillsApp());
}

class FootballSkillsApp extends StatelessWidget {
  const FootballSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Football Skills',
      debugShowCheckedModeBanner: false,

      // --- 🎨 App Theme: Vibrant Football Colors ---
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5), // A strong blue
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green, // Primary color for most elements
          accentColor: Colors.amber, // Accent color for highlights/XP
        ).copyWith(
          secondary: Colors.amber,
          surface: const Color(0xFFF0F4F8), // Light background for contrast
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Inter', // A modern, clean font

        // Custom button style for a uniform, rounded look
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 4,
          ),
        ),
        useMaterial3: true,
      ),

      // --- 🚀 Navigation Routes ---
      initialRoute: '/',
      routes: {
        // Child Flow
        '/': (context) => const SplashScreen(), // Initial Splash
        '/login': (context) => const LoginSignupScreen(), // Child Login
        '/training': (context) => const TrainingScreen(), // Drill List Page
        '/avatar': (context) => const AvatarScreen(), // Avatar Customization
        '/rewards': (context) => const RewardsScreen(), // Rewards/Badges
        '/progress': (context) => const ProgressScreen(), // History/Progress
        '/settings': (context) => const SettingsScreen(), // Settings

        // Parent Flow
        '/parent-login': (context) => const ParentLoginScreen(),
        '/parent-home': (context) => const ParentDashboardScreen(),
        '/parent-registration': (context) => const ParentRegistrationScreen(), 
        '/parent-notifications': (context) => const ParentNotificationsScreen(),
      },
      // Using onGenerateRoute to handle passing arguments (like the name/data)
      onGenerateRoute: (settings) {
        if (settings.name == '/parent-child-detail') {
          // Parent Detail screen arguments (Map<String, dynamic>)
          final args = settings.arguments as Map<String, dynamic>; 
          return MaterialPageRoute(
            builder: (context) {
              return ParentChildDetailScreen(childData: args);
            },
          );
        } else if (settings.name == '/child-home') {
          // Child Dashboard screen arguments (String playerName)
          final playerName = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) {
              // Pass the received name, or a default name if null
              return ChildDashboardScreen(playerName: playerName ?? 'Future Star');
            },
          );
        } else if (settings.name == '/drill-detail') {
          // NEW ROUTE for Drill Detail Screen
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