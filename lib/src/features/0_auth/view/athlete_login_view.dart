import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
import '../viewmodel/athlete_login_viewmodel.dart';

class AthleteLoginView extends StatefulWidget {
  const AthleteLoginView({super.key});

  @override
  State<AthleteLoginView> createState() => _AthleteLoginViewState();
}

class _AthleteLoginViewState extends State<AthleteLoginView> {
  final _viewModel = AthleteLoginViewModel();

  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _athleteNameController.dispose();
    _pinController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAthleteLogin() async {
    if (_formKey.currentState!.validate()) {
      // 1. Call Login
      final athleteData = await _viewModel.loginAthlete(
        name: _athleteNameController.text.trim(),
        pin: _pinController.text.trim(),
      );

      // 2. If successful, navigate to Dashboard
      if (athleteData != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/athlete-home',
          (route) => false,
          arguments: athleteData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Athlete Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sports_gymnastics,
                    size: 80, color: Colors.blue),
                const SizedBox(height: 30),
                Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // USERNAME
                TextFormField(
                  controller: _athleteNameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your username" : null,
                ),
                const SizedBox(height: 20),

                // PIN
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: "4-Digit PIN",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    counterText: "", // Hide character counter
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value!.length != 4 ? "PIN must be 4 digits" : null,
                ),
                const SizedBox(height: 30),

                // LOGIN BUTTON
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleAthleteLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Log In", style: TextStyle(fontSize: 18)),
                ),
                
                const SizedBox(height: 20),

                // --- NEW: CREATE ACCOUNT BUTTON ---
                OutlinedButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          // Navigate to the Signup View
                          Navigator.of(context).pushNamed('/athlete-signup');
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                  child: const Text("New Athlete? Create Profile"),
                ),
                
                const SizedBox(height: 20),
                
                // Existing Coach Link
                TextButton(
                  onPressed: () {
                     Navigator.of(context).pushNamed('/coach-login');
                  },
                  child: const Text("Are you a Coach? Log in here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}