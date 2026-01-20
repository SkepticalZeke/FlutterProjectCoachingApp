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
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleAthleteLogin() async {
    if (_formKey.currentState!.validate()) {
      final athleteData = await _viewModel.loginAthlete(
        name: _athleteNameController.text.trim(),
        pin: _pinController.text.trim(),
      );

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
    final primaryColor = theme.primaryColor;

    return Scaffold(
      // Allow the body to extend behind the AppBar for a full-screen feel
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Athlete Login"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // 1. DARK BACKGROUND
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. LOGO CONTAINER WITH SHADOW
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 116, 102, 102),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.sports_gymnastics,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 30),

                // 3. MAIN CARD CONTAINER
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Welcome Back!",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to access your training",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // USERNAME FIELD
                        TextFormField(
                          controller: _athleteNameController,
                          decoration: _inputDecoration("Username", Icons.person),
                          validator: (value) =>
                              value!.isEmpty ? "Enter your username" : null,
                        ),
                        const SizedBox(height: 20),

                        // PIN FIELD
                        TextFormField(
                          controller: _pinController,
                          decoration: _inputDecoration("4-Digit PIN", Icons.lock)
                              .copyWith(counterText: ""),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) => value!.length != 4
                              ? "PIN must be 4 digits"
                              : null,
                        ),
                        const SizedBox(height: 32),

                        // 4. CYAN LOGIN BUTTON
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00BCD4).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _viewModel.isLoading
                                ? null
                                : _handleAthleteLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _viewModel.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. CLEANER BOTTOM LINKS
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushNamed('/athlete-signup');
                        },
                  child: RichText(
                    text: TextSpan(
                      text: "New Athlete? ",
                      style: TextStyle(color: Colors.grey.shade400),
                      children: [
                        TextSpan(
                          text: "Create Profile",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/coach-login');
                  },
                  child: Text(
                    "Are you a Coach? Log in here",
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for cleaner Input Decoration
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      // Default State
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      // Enabled (Not focused)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      // Focused (Active)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
      // Error State
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}