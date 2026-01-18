import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AthleteSignupViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _registeredAthleteData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get registeredAthleteData => _registeredAthleteData;

  Future<bool> registerSelf({
    required String displayName, // <--- NEW PARAMETER
    required String username,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        '/auth/athlete/register-self', 
        {
          'displayName': displayName, // <--- Send to Server
          'username': username, 
          'pin': pin
        }, 
        authRequired: false 
      );

      _registeredAthleteData = response;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}