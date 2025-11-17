import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import our Model
import '../../../core/services/auth_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Login View.
*/
class CoachLoginViewModel extends ChangeNotifier {
  // 1. Import the repository
  final AuthRepository _authRepo = AuthRepository();

  // 2. State
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. Logic
  Future<bool> loginCoach({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Call the Auth Repository to log in
      final User? user = await _authRepo.loginCoachWithEmail(email, password);

      if (user != null) {
        // Success
        _setLoading(false);
        return true;
      } else {
        // This should not happen if signInWithEmailAndPassword succeeds
        _setError('An unknown error occurred.');
        _setLoading(false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        _setError('Invalid email or password.');
      } else if (e.code == 'invalid-email') {
        _setError('The email address is not valid.');
      } else {
        _setError('An error occurred: ${e.message}');
      }
      _setLoading(false);
      return false;
    } catch (e) {
      // Handle other errors
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 5. Helper functions
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