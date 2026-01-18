import 'package:flutter/material.dart';
import '../viewmodel/coach_registration_viewmodel.dart';

class CoachRegistrationView extends StatefulWidget {
  const CoachRegistrationView({super.key});

  @override
  State<CoachRegistrationView> createState() => _CoachRegistrationViewState();
}

class _CoachRegistrationViewState extends State<CoachRegistrationView> {
  final _viewModel = CoachRegistrationViewModel();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers (Athlete controllers removed)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    setState(() {});
  }

  // Handle Registration
  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Call ViewModel (No athlete args passed)
    bool success = await _viewModel.registerCoach(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      // Navigate to Dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/coach-dashboard', // Ensure this matches your main.dart route
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Welcome.')),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.sports, // Changed to whistle icon
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Create Coach Account',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage your team and track athlete stats.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // --- Name ---
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- Email ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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

                // --- Password ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
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
                const SizedBox(height: 30),

                // --- Button ---
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Back to Login
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushReplacementNamed('/coach-login');
                        },
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