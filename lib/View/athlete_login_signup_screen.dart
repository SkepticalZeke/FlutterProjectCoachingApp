import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORT ⭐️
import 'package:cloud_firestore/cloud_firestore.dart';

class AthleteLoginSignupScreen extends StatefulWidget {
  const AthleteLoginSignupScreen({super.key});

  @override
  State<AthleteLoginSignupScreen> createState() =>
      _AthleteLoginSignupScreenState();
}

class _AthleteLoginSignupScreenState extends State<AthleteLoginSignupScreen> {
  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // ⭐️ To control loading spinner

  // ⭐️ GET FIREBASE INSTANCE ⭐️
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ UPDATED LOGIN FUNCTION ⭐️
  void _handleStartTraining(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final athleteName = _athleteNameController.text.trim();
    final pin = _pinController.text.trim();

    try {
      // 1. Query Firestore for an athlete with matching name AND pin
      final QuerySnapshot snapshot = await _firestore
          .collection('athletes')
          .where('name', isEqualTo: athleteName)
          .where('pin', isEqualTo: pin)
          .limit(1) // We only expect one match
          .get();

      // 2. Check if we found a match
      if (snapshot.docs.isNotEmpty) {
        // 3. Match found! Get the athlete's data
        final athleteDoc = snapshot.docs.first;
        final athleteData = athleteDoc.data() as Map<String, dynamic>;

        // ⭐️ IMPORTANT: Add the document ID to the data map ⭐️
        // This is crucial for the dashboard to know which document to update
        athleteData['id'] = athleteDoc.id;

        // 4. Navigate to the athlete's home, passing the entire data map
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/athlete-home',
            arguments:
                athleteData, // ⭐️ Pass the full map, not just the name
          );
        }
      } else {
        // 5. No match found
        _showErrorSnackBar('Invalid name or PIN. Please try again.');
      }
    } catch (e) {
      // 6. Handle any other errors
      _showErrorSnackBar('An error occurred: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⭐️ HELPER FUNCTION FOR ERRORS ⭐️
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _athleteNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

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

                // Athlete Name Input
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

                // PIN Input
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

                // Main Login Button
                ElevatedButton(
                  // ⭐️ Wire up loading state ⭐️
                  onPressed: _isLoading ? null : () => _handleStartTraining(context),
                  child: _isLoading
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

                // Forgot Name/PIN
                TextButton(
                  onPressed: _isLoading ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Contact your coach to recover your name or PIN.')),
                    );
                  },
                  child: const Text('Forgot Name or PIN?'),
                ),

                // --- Coach Sign Up ---
                OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pushNamed('/coach-registration');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('New Coach? Sign Up Here'),
                ),
                const SizedBox(height: 30),

                // --- Coach Access Login ---
                TextButton(
                  onPressed: _isLoading ? null : () {
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