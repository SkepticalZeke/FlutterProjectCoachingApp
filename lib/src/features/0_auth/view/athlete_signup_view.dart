import 'package:flutter/material.dart';
// Import the new ViewModel and Model
import '../viewmodel/athlete_signup_viewmodel.dart';
import '../../../core/models/athlete.dart';

/*
  VIEW (V)
  Refactored AthleteSignupView with:
  - Gradient Background
  - Modern Form Styling
  - Clear Instructions
  - Polished Input Fields
*/
class AthleteSignupView extends StatefulWidget {
  const AthleteSignupView({super.key});

  @override
  State<AthleteSignupView> createState() => _AthleteSignupViewState();
}

class _AthleteSignupViewState extends State<AthleteSignupView> {
  // 1. The View owns its ViewModel
  final _viewModel = AthleteSignupViewModel();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

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
    _nameController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // 4. Rebuild UI and show errors
  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    setState(() {}); // Rebuild to update loading spinner
  }

  // 5. "handle" function now calls the ViewModel
  void _handleNewPlayerRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Athlete? newAthlete = await _viewModel.registerAthlete(
      name: _nameController.text.trim(),
      pin: _pinController.text.trim(),
      coachEmail: _codeController.text.trim(),
    );

    // 6. View handles navigation
    if (newAthlete != null && mounted) {
      // Convert Athlete object to Map for navigation
      final athleteData = {
        'id': newAthlete.id,
        'name': newAthlete.name,
        'pin': newAthlete.pin,
        'coachUid': newAthlete.coachUid,
        'level': newAthlete.level,
        'streak': newAthlete.streak,
        'progress': newAthlete.progress,
        'status': newAthlete.status,
        'skill_focus': newAthlete.skillFocus,
        'difficulty': newAthlete.difficulty,
        'stars': newAthlete.stars,
        'selectedOutfit': newAthlete.selectedOutfit,
        'selectedShoe': newAthlete.selectedShoe,
        'selectedEquipment': newAthlete.selectedEquipment,
        'currentXp': newAthlete.currentXp,
        'requiredXp': newAthlete.requiredXp,
        'totalXp': newAthlete.totalXp,
      };

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/athlete-home',
        (Route<dynamic> route) => false,
        arguments: athleteData,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Welcome to the team!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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

  // 7. Build method
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
        title: const Text("Create Profile", style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Join Your Team',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your athlete profile to start training.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildInputField(
                      controller: _nameController,
                      label: 'Your Name / Nickname',
                      icon: Icons.person_outline_rounded,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please choose a nickname.' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _pinController,
                      label: 'Create 4-Digit PIN',
                      icon: Icons.lock_outline_rounded,
                      isNumber: true,
                      maxLength: 4,
                      validator: (value) => value == null || value.length != 4
                          ? 'Please enter a 4-digit PIN.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _codeController,
                      label: "Coach's Email Address",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || !value.contains('@')
                          ? 'Please enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _handleNewPlayerRegistration,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // Helper for cleaner input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? (isNumber ? TextInputType.number : TextInputType.text),
      obscureText: isNumber, // Only obscure if it's the PIN
      maxLength: maxLength,
      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: colorScheme.secondary),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}