import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/coach_registration_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is now "dumb".
  It doesn't know Firebase exists.
  It only talks to the ViewModel.
*/
class CoachRegistrationView extends StatefulWidget {
  const CoachRegistrationView({super.key});

  @override
  State<CoachRegistrationView> createState() => _CoachRegistrationViewState();
}

class _CoachRegistrationViewState extends State<CoachRegistrationView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachRegistrationViewModel();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _athletePinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Listen for changes in the ViewModel
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    // 3. Clean up the listener and controllers
    _viewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _athleteNameController.dispose();
    _athletePinController.dispose();
    super.dispose();
  }

  // 4. This function is called by the ViewModel to rebuild the UI
  void _onViewModelChanged() {
    // Show error snackbar if there's a new error
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    // Rebuild the widget to update the loading spinner
    setState(() {});
  }

  // 5. The View's "handle" function just calls the ViewModel
  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Call the ViewModel to do the work
    bool success = await _viewModel.registerCoach(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      athleteName: _athleteNameController.text.trim(),
      athletePin: _athletePinController.text.trim(),
    );

    // 6. The View handles the navigation result
    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/coach-home',
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created! Welcome to CoachFitness.')),
      );
    }
    // Error handling is now done by the _onViewModelChanged listener
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 7. The build method now reads state from the ViewModel
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
                Icon(Icons.group_add,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Create Your Coach Account',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Coach Account Details ---
                Text(
                  '1. Coach Account',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 40),

                // --- First Athlete Details ---
                Text(
                  '2. First Athlete Setup',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _athleteNameController,
                  decoration: InputDecoration(
                    labelText: 'Athlete Name / Nickname',
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a nickname for the athlete.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _athletePinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
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

                // 8. Button now reads state from the ViewModel
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleRegistration,
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
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