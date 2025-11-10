import 'package:flutter/material.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _handleStartTraining(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final playerName = _playerNameController.text.trim();
      final pin = _pinController.text.trim();
      
      // --- Firebase Placeholder ---
      // Here you would check if the playerName and PIN match a stored child record.
      debugPrint('Attempting login for $playerName with PIN $pin');

      // Simulate network delay and assumed success
      Future.delayed(const Duration(seconds: 1), () {
        // Navigate to the child dashboard, passing the entered name
        Navigator.of(context).pushReplacementNamed(
          '/child-home',
          arguments: playerName,
        );
      });
    }
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CoachFitness Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_pin, size: 80, color: Colors.green),
                const SizedBox(height: 10),
                const Text(
                  'Welcome Back, User!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Player Name Input 
                TextFormField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name / Nickname',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your User Name';
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
                  maxLength: 4, // Max length is 4 digits
                  decoration: const InputDecoration(
                    labelText: '4-Digit PIN',
                    counterText: '', // Hide the counter
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 4 || int.tryParse(value) == null) {
                      return 'PIN must be 4 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Main Login Button
                ElevatedButton(
                  onPressed: () => _handleStartTraining(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Start Training',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Child Action Links ---
                // Forgot Name/PIN
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact your coach to recover your name or PIN.')),
                    );
                  },
                  child: const Text('Forgot Name or PIN?', style: TextStyle(color: Colors.grey)),
                ),
                
                // --- Parent Sign Up (New flow) ---
                OutlinedButton(
                  onPressed: () {
                    // Navigate to the Parent Registration screen for account setup
                    Navigator.of(context).pushNamed('/coach-registration');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.amber),
                  ),
                  child: const Text('New User? Coach Sign Up Here', style: TextStyle(color: Colors.amber)),
                ),

                const SizedBox(height: 30),
                
                // --- Parent Access Login ---
                TextButton(
                  onPressed: () {
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