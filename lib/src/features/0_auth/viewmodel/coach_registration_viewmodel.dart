import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Registration View.
  It uses ChangeNotifier to notify the View when the state changes.
  It's the only thing that talks to the Repositories.
*/
class CoachRegistrationViewModel extends ChangeNotifier {
  // 1. Import the repositories (our Model)
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State is held in the ViewModel
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters for the View to read the state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. This is the main logic, moved from the old file
  Future<bool> registerCoach({
    required String email,
    required String password,
    required String athleteName,
    required String athletePin,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Step 1: Call the Auth Repository to create the user
      final User? newCoach =
          await _authRepo.registerCoachWithEmail(email, password);

      if (newCoach != null) {
        // Step 2: Call the Database Repository to save the data
        await _dbRepo.createCoachAndFirstAthlete(
          coachUid: newCoach.uid,
          coachEmail: email,
          athleteName: athleteName,
          athletePin: athletePin,
        );

        // Success
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create user.');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
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
      // Handle other errors (like from the database)
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 5. Helper functions to update state and notify the View
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // This tells the View to rebuild
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners(); // This tells the View to rebuild
  }

  void _clearError() {
    _errorMessage = null;
  }
}