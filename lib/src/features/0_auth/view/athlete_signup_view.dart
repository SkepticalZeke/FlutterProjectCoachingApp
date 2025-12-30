import 'package:flutter/material.dart';
// Import the new ViewModel and Model
import '../viewmodel/athlete_signup_viewmodel.dart';
import '../../../core/models/athlete.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
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
        const SnackBar(
            content: Text('Registration complete! Welcome to CoachFitness.')),
      );
    }
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
      appBar: AppBar(title: const Text('New Athlete Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.add_task,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Let\'s build your profile!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter your details and the email from your coach.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                      labelText: 'Your Name / Nickname', icon: Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please choose a nickname.';
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
                  decoration: _buildInputDecoration(
                      labelText: '4-Digit PIN (for login)',
                      icon: Icons.lock_outline),
                  validator: (value) {
                    if (value == null ||
                        value.length != 4 ||
                        int.tryParse(value) == null) {
                      return 'Please enter a valid 4-digit PIN.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // ⭐️ Relabeled "Team Code" to "Coach's Email" ⭐️
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                      labelText: 'Coach\'s Email', icon: Icons.group),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Please enter your coach\'s email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      _viewModel.isLoading ? null : _handleNewPlayerRegistration,
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
                        )
                      : const Text(
                          'Join Team and Start',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _viewModel.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Already have an account? Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget (UI Only)
  InputDecoration _buildInputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      counterText: '', // Hide counter for PIN field
    );
  }
}