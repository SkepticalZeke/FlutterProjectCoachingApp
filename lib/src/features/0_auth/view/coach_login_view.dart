import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/coach_login_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class CoachLoginView extends StatefulWidget {
  const CoachLoginView({super.key});

  @override
  State<CoachLoginView> createState() => _CoachLoginViewState();
}

class _CoachLoginViewState extends State<CoachLoginView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachLoginViewModel();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Initialize the ViewModel
    _viewModel.init();
    // 3. Listen for changes
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 4. Function to rebuild UI and show errors
  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    setState(() {});
  }

  // 5. "handle" function now calls the ViewModel
  void _handleCoachLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    bool success = await _viewModel.loginCoach(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 6. View handles navigation
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/coach-dashboard'); 
      // Note: Ensure this matches your route name in main.dart (usually /coach-dashboard)
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.sports, // Changed icon to Whistle for Coach
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'Manage your team and track drills.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                
                // EMAIL
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
                
                // PASSWORD
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
                
                // LOGIN BUTTON
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleCoachLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // --- NEW: LINK TO REGISTRATION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _viewModel.isLoading ? null : () {
                        // Navigate to the Registration View
                        Navigator.of(context).pushNamed('/coach-registration');
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}