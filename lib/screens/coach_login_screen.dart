import 'package:flutter/material.dart';

// 1. Class name refactored: ParentLoginScreen -> CoachLoginScreen
class CoachLoginScreen extends StatefulWidget {
  const CoachLoginScreen({super.key});

  @override
  State<CoachLoginScreen> createState() => _CoachLoginScreenState();
}

class _CoachLoginScreenState extends State<CoachLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. Function name refactored: _handleParentLogin -> _handleCoachLogin
  void _handleCoachLogin() {
    // 1. Check Form Validation
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // --- Firebase Placeholder ---
      debugPrint('Validation Succeeded. Starting simulated login...');

      // Simulate network delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // 2. Navigation
        // This route name '/coach-home' already matches our main.dart
        Navigator.of(context).pushReplacementNamed('/coach-home');
        debugPrint('Navigation to /coach-home successful.');
      });
    } else {
      debugPrint('Validation Failed. Not navigating.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. UI Theme: Use theme colors for a consistent look
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // 4. Text refactored: 'Coach Access' (already correct)
        title: const Text('Coach Access'),
        // AppBar color is now controlled by main.dart theme
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 5. UI Theme: Icon updated to be a "coach" icon and use cyan color
                Icon(Icons.sports,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                // 6. Text refactored: Updated descriptive text
                Text(
                  'Monitor athlete progress and manage training.',
                  textAlign: TextAlign.center,
                  // 7. UI Theme: Explicitly use theme text color for light grey
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // 8. UI Theme: Styled TextFormField for dark mode
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    // Use theme's border color
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon:
                        Icon(Icons.email, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 9. UI Theme: Styled TextFormField for dark mode
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon:
                        Icon(Icons.lock, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // 10. Login Button (with Loading State)
                ElevatedButton(
                  // 11. Function refactored: _handleCoachLogin
                  onPressed: _isLoading ? null : _handleCoachLogin,
                  // Button style is now controlled by main.dart theme
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            // 12. UI Theme: Use black for spinner on cyan button
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // 13. Text refactored: "Child Join Code" -> "Athlete Join Code"
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // This will open the feature for coaches to link to an athlete account
                  },
                  child: const Text(
                    'Have an Athlete Join Code?',
                    // TextButton color is now controlled by main.dart theme
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}