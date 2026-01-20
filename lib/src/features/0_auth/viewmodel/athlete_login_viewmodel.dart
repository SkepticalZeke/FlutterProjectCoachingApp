import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';
import '../../../core/services/auth_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Login View.
*/
class AthleteLoginViewModel extends ChangeNotifier {
  // 1. Import the repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();
  final AuthRepository _authRepo = AuthRepository();

  // 2. State
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize session service
  Future<void> init() async {
    await _authRepo.init();
  }

  // 4. Logic
  // Tries to log in. Returns the athlete's data map if successful,
  // otherwise returns null.
  Future<Map<String, dynamic>?> loginAthlete({
    required String name,
    required String pin,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Call the Database Repository to find the athlete
      final Map<String, dynamic>? athleteData =
          await _dbRepo.getAthleteByNameAndPin(name, pin);

      if (athleteData != null) {
        // Success - save the session
        try {
          await _authRepo.saveAthleteSession(athleteData);
        } catch (e) {
          // Log warning but don't fail login if session save fails
          debugPrint('Warning: Failed to save session: $e');
        }
        
        _setLoading(false);
        return athleteData;
      } else {
        // No match found
        _setError('Invalid name or PIN. Please try again.');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      // Handle other errors (like permissions)
      _setError(e.toString());
      _setLoading(false);
      return null;
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