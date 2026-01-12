import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/athlete_login_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class AthleteLoginView extends StatefulWidget {
  const AthleteLoginView({super.key});

  @override
  State<AthleteLoginView> createState() => _AthleteLoginViewState();
}

class _AthleteLoginViewState extends State<AthleteLoginView> {
  // 1. The View owns its ViewModel
  final _viewModel = AthleteLoginViewModel();

  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 2. Listen for changes
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    // 3. Clean up
    _viewModel.removeListener(_onViewModelChanged);
    _athleteNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // 4. Function to rebuild UI and show errors
  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    setState(() {}); // Rebuild to update loading spinner
  }

  // 5. "handle" function now calls the ViewModel
  void _handleStartTraining() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Call the ViewModel to do the work
    final Map<String, dynamic>? athleteData =
        await _viewModel.loginAthlete(
      name: _athleteNameController.text.trim(),
      pin: _pinController.text.trim(),
    );

    // 6. View handles navigation
    if (athleteData != null && mounted) {
      // Pass the full data map (which includes the ID)
      Navigator.of(context).pushReplacementNamed(
        '/athlete-home',
        arguments: athleteData,
      );
    }
    // Error snackbar is handled by _onViewModelChanged
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 7. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                Icon(Icons.person_pin,
                    size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Welcome Back, Athlete!',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _athleteNameController,
                  decoration: InputDecoration(
                    labelText: 'Athlete Name / Nickname',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Athlete Name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                // 8. Button reads state from ViewModel
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleStartTraining,
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
                        )
                      : const Text(
                          'Start Training',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          _showErrorSnackBar(
                              'Contact your coach to recover your name or PIN.');
                        },
                  child: const Text('Forgot Name or PIN?'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Back to Role Selection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}