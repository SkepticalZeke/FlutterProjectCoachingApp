import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/coach_registration_viewmodel.dart';

/*
  VIEW (V)
  Refactored CoachRegistrationView with:
  - Gradient Background
  - Modern "Glass" Card UI
  - Polished Input Fields
  - Clear Navigation Hierarchy
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Account created! Welcome.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    // Error handling is now done by the _onViewModelChanged listener
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 7. The build method now reads state from the ViewModel
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.1) ?? Colors.grey[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Icon Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.group_add_rounded,
                      size: 50,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registration Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create Account',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set up your coach profile and add your first athlete.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- Coach Account Details ---
                          _buildSectionHeader(context, '1. Coach Credentials'),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || value.isEmpty || !value.contains('@')
                                    ? 'Enter a valid email.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            validator: (value) => value == null || value.length < 6
                                ? 'Password must be at least 6 characters.'
                                : null,
                          ),
                          const SizedBox(height: 32),

                          // --- First Athlete Details ---
                          _buildSectionHeader(context, '2. First Athlete Setup'),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _athleteNameController,
                            label: 'Athlete Name / Nickname',
                            icon: Icons.person_outline_rounded,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter a nickname.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _athletePinController,
                            label: '4-Digit PIN (for athlete)',
                            icon: Icons.pin_rounded,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            validator: (value) => value == null ||
                                    value.length != 4 ||
                                    int.tryParse(value) == null
                                ? 'Enter a 4-digit PIN.'
                                : null,
                          ),
                          const SizedBox(height: 40),

                          // Action Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _viewModel.isLoading ? null : _handleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 4,
                                shadowColor: colorScheme.primary.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _viewModel.isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'Complete Registration',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}