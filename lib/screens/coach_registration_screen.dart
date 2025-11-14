import 'package:flutter/material.dart';

// 1. Class name refactored
class CoachRegistrationScreen extends StatefulWidget {
  const CoachRegistrationScreen({super.key});

  @override
  // 2. State class refactored
  State<CoachRegistrationScreen> createState() =>
      _CoachRegistrationScreenState();
}

class _CoachRegistrationScreenState extends State<CoachRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // 3. Controller refactored: _playerNameController -> _athleteNameController
  final TextEditingController _athleteNameController = TextEditingController();
  // 4. Controller refactored: _playerPinController -> _athletePinController
  final TextEditingController _athletePinController = TextEditingController();
  bool _isLoading = false;

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // --- Firebase Placeholder ---
      // 5. Text refactored: 'User Setup' -> 'Athlete Setup'
      debugPrint('Attempting Coach Registration and Athlete Setup...');

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isLoading = false;
        });

        // 6. Navigation: This route '/coach-home' is correct
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/coach-home',
          (Route<dynamic> route) => false, // Clears the stack
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account created! Welcome to CoachFitness.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // 7. Dispose refactored controllers
    _athleteNameController.dispose();
    _athletePinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 8. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 9. UI Theme: Use primary cyan color
                Icon(Icons.group_add,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Create Your Coach Account',
                  // 10. UI Theme: Use theme text style
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Coach Account Details ---
                Text(
                  '1. Coach Account',
                  // 11. UI Theme: Style uses theme color, which is correct
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // 12. UI Theme: Add border and icon color
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon:
                        Icon(Icons.email, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  // 13. UI Theme: Add border and icon color
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    prefixIcon:
                        Icon(Icons.lock, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 14. Text refactored: 'User Setup' -> 'Athlete Setup'
                Text(
                  '2. First Athlete Setup',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  // 15. Controller refactored
                  controller: _athleteNameController,
                  // 16. UI Theme: Add border and icon color
                  decoration: InputDecoration(
                    // 17. Text refactored
                    labelText: 'Athlete Name / Nickname',
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // 18. Text refactored
                      return 'Please enter a nickname for the athlete.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  // 19. Controller refactored
                  controller: _athletePinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  // 20. UI Theme: Add border and icon color
                  decoration: InputDecoration(
                    // 21. Text refactored
                    labelText: '4-Digit PIN (for athlete login)',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
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

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  // 22. UI Theme: Removed style, uses main.dart theme
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          // 23. UI Theme: Spinner is black (for on-cyan button)
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
                        )
                      : const Text(
                          // 24. Text refactored: More accurate text
                          'Create Account',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Back to Login
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushReplacementNamed('/coach-login');
                        },
                  // 25. UI Theme: Removed style, uses main.dart theme
                  child: const Text('Already have a Coach account? Log In.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}