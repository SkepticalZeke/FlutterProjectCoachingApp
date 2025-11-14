import 'package:flutter/material.dart';

// 1. Class name refactored: LoginSignupScreen -> AthleteLoginSignupScreen
class AthleteLoginSignupScreen extends StatefulWidget {
  const AthleteLoginSignupScreen({super.key});

  @override
  State<AthleteLoginSignupScreen> createState() =>
      _AthleteLoginSignupScreenState();
}

// 2. State class refactored
class _AthleteLoginSignupScreenState extends State<AthleteLoginSignupScreen> {
  // 3. Variable refactored: _playerNameController -> _athleteNameController
  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _handleStartTraining(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // 4. Variable refactored: playerName -> athleteName
      final athleteName = _athleteNameController.text.trim();
      final pin = _pinController.text.trim();

      // --- Firebase Placeholder ---
      debugPrint('Attempting login for $athleteName with PIN $pin');

      // Simulate network delay and assumed success
      Future.delayed(const Duration(seconds: 1), () {
        // 5. Navigation refactored: '/child-home' -> '/athlete-home'
        Navigator.of(context).pushReplacementNamed(
          '/athlete-home',
          // 6. Arguments refactored: Pass athleteName
          arguments: athleteName,
        );
      });
    }
  }

  @override
  void dispose() {
    // 7. Dispose refactored controller
    _athleteNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 8. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      // 9. Text refactored: More specific title
      appBar: AppBar(title: const Text('Athlete Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 10. UI Theme: Use primary cyan color
                Icon(Icons.person_pin,
                    size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                // 11. Text refactored: 'User' -> 'Athlete'
                Text(
                  'Welcome Back, Athlete!',
                  // 12. UI Theme: Use theme text styles
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // 13. Athlete Name Input
                TextFormField(
                  // 14. Controller refactored
                  controller: _athleteNameController,
                  decoration: InputDecoration(
                    // 15. Text refactored
                    labelText: 'Athlete Name / Nickname',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    // 16. UI Theme: Use primary cyan color
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // 17. Text refactored
                      return 'Please enter your Athlete Name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // PIN Input
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: '4-Digit PIN',
                    counterText: '',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    // 18. UI Theme: Use primary cyan color
                    prefixIcon:
                        Icon(Icons.lock, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.length != 4 ||
                        int.tryParse(value) == null) {
                      return 'PIN must be 4 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Main Login Button
                ElevatedButton(
                  onPressed: () => _handleStartTraining(context),
                  // 19. UI Theme: Removed style, now uses main.dart theme
                  child: const Text(
                    'Start Training',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Forgot Name/PIN
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      // 20. Text refactored: This message is perfect
                      const SnackBar(
                          content: Text(
                              'Contact your coach to recover your name or PIN.')),
                    );
                  },
                  // 21. UI Theme: Removed style, uses theme default
                  child: const Text('Forgot Name or PIN?'),
                ),

                // --- Coach Sign Up ---
                OutlinedButton(
                  onPressed: () {
                    // 22. Navigation: This route is correct
                    Navigator.of(context).pushNamed('/coach-registration');
                  },
                  // 23. UI Theme: Style outline button for dark mode
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  // 24. Text refactored: 'User' -> 'Coach'
                  child: const Text('New Coach? Sign Up Here'),
                ),
                const SizedBox(height: 30),

                // --- Coach Access Login ---
                TextButton(
                  onPressed: () {
                    // 25. Navigation: This route is correct
                    Navigator.of(context).pushNamed('/coach-login');
                  },
                  child: const Text('Already a Coach? Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}