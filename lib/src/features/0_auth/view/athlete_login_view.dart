import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/athlete_login_viewmodel.dart';

/*
  VIEW (V)
  Refactored AthleteLoginView with:
  - Gradient Background
  - Elevated Login Card
  - Modern Input Fields
  - Polished Typography & Iconography
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
      ),
      // Background Gradient
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_run_rounded,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Login Card
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
                          'Welcome Back!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your details to train',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Name Input
                        TextFormField(
                          controller: _athleteNameController,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Athlete Name',
                            hintText: 'e.g. John Doe',
                            prefixIcon: Icon(Icons.person_rounded, color: colorScheme.primary),
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
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Name';
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
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 8
                          ),
                          decoration: InputDecoration(
                            labelText: '4-Digit PIN',
                            counterText: '',
                            prefixIcon: Icon(Icons.lock_rounded, color: colorScheme.primary),
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
                          validator: (value) {
                            if (value == null ||
                                value.length != 4 ||
                                int.tryParse(value) == null) {
                              return 'PIN must be 4 digits.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Action Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _viewModel.isLoading ? null : _handleStartTraining,
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
                                    'Start Training',
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
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          _showErrorSnackBar(
                              'Contact your coach to recover your name or PIN.');
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                  ),
                  child: const Text('Forgot Name or PIN?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}