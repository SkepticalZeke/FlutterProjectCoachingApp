import 'package:flutter/material.dart';
// Import our Models
import '../../../core/models/athlete.dart';
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Signup View.
*/
class AthleteSignupViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. Logic
  Future<Athlete?> registerAthlete({
    required String name,
    required String pin,
    required String coachEmail,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Step 1: Call the Database Repository to create the athlete
      final newAthlete = await _dbRepo.registerNewAthlete(
        name: name,
        pin: pin,
        coachEmail: coachEmail,
      );

      _setLoading(false);
      return newAthlete; // Success, return the new Athlete object
    } catch (e) {
      // Handle errors (e.g., "Coach not found")
      _setError(e.toString());
      _setLoading(false);
      return null; // Failed
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