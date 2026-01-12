import 'package:flutter/material.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/api_service.dart';

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
  final ApiService _api = ApiService();

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

    debugPrint('🔵 Starting coach registration for: $email');

    try {
      // Step 1: Call the Auth Repository to create the user via API
      debugPrint('🔵 Calling API to register coach...');
      final response = await _authRepo.registerCoachWithEmail(email, password);
      debugPrint('🟢 Registration API response received');

      if (response['token'] != null && response['coachUid'] != null) {
        // Store the auth token and coachUid
        debugPrint('🟢 Token received, saving coach data...');
        _api.setToken(response['token'], coachUid: response['coachUid']);

        // Step 2: Call the Database Repository to save the data
        debugPrint('🔵 Creating coach and first athlete...');
        await _dbRepo.createCoachAndFirstAthlete(
          coachUid: response['coachUid'],
          coachEmail: email,
          athleteName: athleteName,
          athletePin: athletePin,
        );

        // Success
        debugPrint('🟢 Registration completed successfully!');
        _setLoading(false);
        return true;
      } else {
        debugPrint('🔴 Invalid response: Missing token or coachUid');
        _setError('Invalid server response. Missing required data.');
        _setLoading(false);
        return false;
      }
    } on ApiException catch (e) {
      // Handle specific API errors
      debugPrint('🔴 API Error [${e.statusCode}]: ${e.message}');
      _setLoading(false);

      // Parse error based on status code and message
      if (e.statusCode == 400) {
        if (e.message.toLowerCase().contains('password')) {
          _setError('Password must be at least 6 characters.');
        } else if (e.message.toLowerCase().contains('email')) {
          _setError('Please enter a valid email address.');
        } else {
          _setError(e.message);
        }
      } else if (e.statusCode == 409 || e.message.toLowerCase().contains('already exists')) {
        _setError('An account with this email already exists.');
      } else if (e.statusCode == 408) {
        _setError('Request timeout. Please check your connection.');
      } else if (e.statusCode == 0) {
        _setError('Cannot connect to server. Please check your internet.');
      } else {
        _setError(e.message.isNotEmpty ? e.message : 'Registration failed. Please try again.');
      }
      return false;
    } catch (e) {
      // Handle unexpected errors
      debugPrint('🔴 Unexpected error: ${e.toString()}');
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
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