import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

class CoachRegistrationViewModel extends ChangeNotifier {
  // 1. Import the repositories
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. Register Logic (Updated: No Athlete Data needed)
  Future<bool> registerCoach({
    required String email,
    required String password,
    required String name, // Added Name so we can save it to the profile
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Step 1: Call Auth Repository
      final User? newCoach =
          await _authRepo.registerCoachWithEmail(email, password);

      if (newCoach != null) {
        // Step 2: Call Database Repository
        // Note: Ensure your DatabaseRepository has a 'createCoachProfile' method
        await _dbRepo.createCoachProfile(
          uid: newCoach.uid,
          email: email,
          name: name,
        );

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create user.');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _setError('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        _setError('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        _setError('The email address is not valid.');
      } else {
        _setError('An error occurred: ${e.message}');
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 5. Helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}