import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORT ⭐️
import 'package:firebase_auth/firebase_auth.dart';

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

  // ⭐️ GET FIREBASE INSTANCE ⭐️
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ⭐️ UPDATED LOGIN FUNCTION ⭐️
  void _handleCoachLogin() async {
    // 1. Check Form Validation
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 2. SIGN IN WITH FIREBASE AUTH
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 3. Navigation (if successful)
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/coach-home');
          debugPrint('Navigation to /coach-home successful.');
        }
      } on FirebaseAuthException catch (e) {
        // 4. HANDLE LOGIN ERRORS
        String message = 'An error occurred. Please try again.';
        // Use 'invalid-credential' as a generic catch-all for wrong email/pass
        if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found' ||
            e.code == 'wrong-password') {
          message = 'Invalid email or password.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        }
        _showErrorSnackBar(message);
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }

      // 5. STOP LOADING (if mounted)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ⭐️ HELPER FUNCTION FOR ERRORS ⭐️
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- The build() method (UI) is unchanged ---
    // It is already themed and wired up correctly
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Access'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.sports,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'Monitor athlete progress and manage training.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
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

                // Password Input
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

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCoachLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
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

                // Athlete Join Code
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // ...
                  },
                  child: const Text(
                    'Have an Athlete Join Code?',
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