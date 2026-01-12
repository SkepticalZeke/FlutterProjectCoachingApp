import 'package:flutter/material.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Existing Logout Logic ---
  Future<void> logout() async {
    try {
      await _authRepo.signOut();
    } catch (e) {
      debugPrint("Error logging out: $e");
    }
  }

  // --- NEW: Update Name ---
  Future<bool> updateName(String athleteId, String newName) async {
    if (newName.trim().isEmpty) {
      _errorMessage = "Name cannot be empty.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _dbRepo.updateAthleteProfile(athleteId: athleteId, newName: newName.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Failed to update name: $e";
      _setLoading(false);
      return false;
    }
  }

  // --- NEW: Update PIN ---
  Future<bool> updatePin(String athleteId, String newPin) async {
    // Basic Validation
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      _errorMessage = "PIN must be exactly 4 digits.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _dbRepo.updateAthleteProfile(athleteId: athleteId, newPin: newPin);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Failed to update PIN: $e";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null; // Clear previous errors
    notifyListeners();
  }
}