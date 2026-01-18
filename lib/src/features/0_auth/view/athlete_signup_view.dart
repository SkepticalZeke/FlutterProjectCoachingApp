import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodel/athlete_signup_viewmodel.dart';

class AthleteSignupView extends StatefulWidget {
  const AthleteSignupView({super.key});

  @override
  State<AthleteSignupView> createState() => _AthleteSignupViewState();
}

class _AthleteSignupViewState extends State<AthleteSignupView> {
  // 1. Initialize ViewModel
  final _viewModel = AthleteSignupViewModel();

  // 2. Controllers
  final _displayNameController = TextEditingController(); // <--- NEW
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _displayNameController.dispose(); // <--- Dispose
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.registeredAthleteData != null) {
      return _buildSuccessView();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("New Athlete Profile")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  "Create Your Account",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),

                // --- NEW: DISPLAY NAME FIELD ---
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: "Display Name (Real Name)",
                    hintText: "e.g. John Doe",
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_viewModel.isLoading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- USERNAME FIELD ---
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username (Login ID)",
                    hintText: "e.g. SpeedDemon99",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  enabled: !_viewModel.isLoading,
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return "Username must be at least 3 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- PIN FIELD ---
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: "Create a 4-Digit PIN",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    filled: true,
                    counterText: "",
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  enabled: !_viewModel.isLoading,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.length != 4) {
                      return "PIN must be exactly 4 digits";
                    }
                    return null;
                  },
                ),

                // --- ERROR FEEDBACK ---
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _viewModel.errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // --- SUBMIT BUTTON ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _viewModel.isLoading ? null : _submit,
                    child: _viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Create Account", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text("Already have an account? Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      _viewModel.registerSelf(
        displayName: _displayNameController.text.trim(), // <--- Pass Name
        username: _usernameController.text.trim(),
        pin: _pinController.text.trim(),
      );
    }
  }

  // --- SUCCESS VIEW ---
  Widget _buildSuccessView() {
    final code = _viewModel.registeredAthleteData?['connectionCode'] ?? 'ERROR';
    // Use the actual Display Name here for a nicer welcome
    final name = _viewModel.registeredAthleteData?['name'] ?? 'Athlete';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                "Welcome, $name!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your account is ready.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              
              const Text(
                "Give this code to your Coach:",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // DISPLAY THE CODE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', 
                      (route) => false
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Go to Login", style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}