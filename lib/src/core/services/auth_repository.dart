import 'api_service.dart';

/*
  MODEL (M)
  This is the Auth Repository. Its only job is to handle authentication
  through the Cloud Run API. It doesn't know about any ViewModels or Views.
  It just does its job and returns data or throws an error.
*/
class AuthRepository {
  final ApiService _api = ApiService();

  // Registers a new coach with email and password
  // Returns user data on success, or throws an error
  // Note: Uses /auth/coach/register endpoint
  Future<Map<String, dynamic>> registerCoachWithEmail(
      String email, String password) async {
    try {
      final response = await _api.post('/auth/coach/register', {
        'email': email,
        'password': password,
      }, authRequired: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logs in a coach
  // Note: Uses /auth/coach/login endpoint
  Future<Map<String, dynamic>> loginCoachWithEmail(
      String email, String password) async {
    try {
      final response = await _api.post('/auth/coach/login', {
        'email': email,
        'password': password,
      }, authRequired: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Signs out the current user (clears local token)
  Future<void> signOut() async {
    try {
      await _api.clearToken();
    } catch (e) {
      throw Exception('An error occurred during sign out: $e');
    }
  }
}