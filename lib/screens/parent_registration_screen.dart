import 'package:flutter/material.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerPinController = TextEditingController();
  bool _isLoading = false;

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // --- Firebase Placeholder ---
      // 1. Create Parent Account (Email/Password Auth).
      // 2. Create the first Child Document (linking it to the parent's UID), storing name and PIN.
      debugPrint('Attempting Coach Registration and User Setup...');

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isLoading = false;
        });
        
        // After successful registration, navigate Parent to their dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/coach-home',
          (Route<dynamic> route) => false, // Clears the stack
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Welcome to CoachFitness.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _playerNameController.dispose();
    _playerPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.group_add, size: 60, color: Colors.green),
                const SizedBox(height: 10),
                const Text(
                  'Create Your Coach Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Parent Account Details ---
                Text(
                  '1. Coach Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (min 6 characters)', prefixIcon: Icon(Icons.lock)),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Password must be at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // --- Child Player Details ---
                Text(
                  '2. First User Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(labelText: ' Name / Nickname', prefixIcon: Icon(Icons.person)),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a nickname for the user.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _playerPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '4-Digit PIN (for user login)',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 4 || int.tryParse(value) == null) return 'PIN must be 4 digits.';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.green),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Register & Start Training',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Back to Login
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pushReplacementNamed('/coach-login');
                  },
                  child: Text('Already have a Coach account? Log In.', style: TextStyle(color: Colors.grey[700])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}