import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORTS ⭐️
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachRegistrationScreen extends StatefulWidget {
  const CoachRegistrationScreen({super.key});

  @override
  State<CoachRegistrationScreen> createState() =>
      _CoachRegistrationScreenState();
}

class _CoachRegistrationScreenState extends State<CoachRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _athleteNameController = TextEditingController();
  final TextEditingController _athletePinController = TextEditingController();
  bool _isLoading = false;

  // ⭐️ GET FIREBASE INSTANCES ⭐️
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ UPDATED REGISTRATION FUNCTION ⭐️
  void _handleRegistration() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }

    // Form is valid, show loading spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create Coach Account (Email/Password Auth).
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newCoach = userCredential.user;

      if (newCoach != null) {
        final String coachUid = newCoach.uid;
        final String coachEmail = _emailController.text.trim();
        final String firstAthleteName = _athleteNameController.text.trim();
        final String firstAthletePin = _athletePinController.text.trim();

        // Use a Batch Write to make both operations atomic (all or nothing)
        WriteBatch batch = _firestore.batch();

        // 2. Create the Coach Document in 'coaches' collection
        // We use the auth UID as the document ID
        DocumentReference coachRef =
            _firestore.collection('coaches').doc(coachUid);
        batch.set(coachRef, {
          'uid': coachUid,
          'email': coachEmail,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Create the first Athlete Document in 'athletes' collection
        DocumentReference athleteRef = _firestore.collection('athletes').doc();
        batch.set(athleteRef, {
          'name': firstAthleteName,
          'pin': firstAthletePin,
          'coachUid': coachUid, // This links the athlete to the coach
          'level': 1,
          'streak': 0,
          'progress': 0.0,
          'status': 'Training Not Started',
          'skill_focus': 'General',
          'difficulty': 'Easy',
          'createdAt': FieldValue.serverTimestamp(),
          'stars': 0,
          'unlockedItems': [101, 201, 301],
          'selectedOutfit': 101,
          'selectedShoe': 201,
          'selectedEquipment': 301,
          'currentXp': 0.0,
          'requiredXp': 1000.0,
          'totalXp': 0,
          // ⭐️⭐️ ADDED THIS MAP ⭐️⭐️
          'skillProgress': {
            'General': 0.0,
            'Agility': 0.0,
            'Strength': 0.0,
            'Cardio': 0.0,
          },
        });

        // Commit both writes at the same time
        await batch.commit();

        // 4. Registration successful, navigate to dashboard
        if (mounted) {
          // 'mounted' check is good practice after an await
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/coach-home',
            (Route<dynamic> route) => false, // Clears the stack
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Account created! Welcome to CoachFitness.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // 5. Handle specific Firebase Auth errors
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      // Handle any other errors (like Firestore permissions)
      _showErrorSnackBar(e.toString());
    }

    // 6. Stop loading spinner, regardless of success or failure
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to show a red error bar
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
    _emailController.dispose();
    _passwordController.dispose();
    _athleteNameController.dispose();
    _athletePinController.dispose();
    super.dispose();
  }

  // --- The build() method (UI) is unchanged ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.group_add,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Create Your Coach Account',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Coach Account Details ---
                Text(
                  '1. Coach Account',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon:
                        Icon(Icons.email, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    prefixIcon:
                        Icon(Icons.lock, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6)
                      return 'Password must be at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // --- First Athlete Details ---
                Text(
                  '2. First Athlete Setup',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _athleteNameController,
                  decoration: InputDecoration(
                    labelText: 'Athlete Name / Nickname',
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter a nickname for the athlete.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _athletePinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '4-Digit PIN (for athlete login)',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: theme.colorScheme.primary),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.length != 4 ||
                        int.tryParse(value) == null)
                      return 'PIN must be 4 digits.';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                // Back to Login
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushReplacementNamed('/coach-login');
                        },
                  child: const Text('Already have a Coach account? Log In.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}