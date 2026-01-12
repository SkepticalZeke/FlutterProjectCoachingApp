import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/auth_repository.dart';
import '../../../core/services/api_service.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Login View.
*/
class CoachLoginViewModel extends ChangeNotifier {
  // 1. Import the repository
  final AuthRepository _authRepo = AuthRepository();
  final ApiService _api = ApiService();

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
      // Call the Auth Repository to log in via API
      final response = await _authRepo.loginCoachWithEmail(email, password);

      // Store the auth token and coachUid from the API response
      if (response['token'] != null) {
        _api.setToken(response['token'], coachUid: response['coachUid']);
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid server response. Missing required data.');
        _setLoading(false);
        return false;
      }
    } on ApiException catch (e) {
      // Handle specific API errors
      _setLoading(false);

      if (e.statusCode == 401 || e.statusCode == 403) {
        _setError('Invalid email or password.');
      } else if (e.statusCode == 404) {
        _setError('Account not found. Please register first.');
      } else if (e.statusCode == 408) {
        _setError('Request timeout. Please check your connection.');
      } else if (e.statusCode == 0) {
        _setError('Cannot connect to server. Please check your internet.');
      } else {
        _setError(e.message.isNotEmpty ? e.message : 'Login failed. Please try again.');
      }
      return false;
    } catch (e) {
      // Handle unexpected errors
      _setLoading(false);
      _setError('An unexpected error occurred: ${e.toString()}');
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