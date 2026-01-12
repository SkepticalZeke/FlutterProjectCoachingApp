import 'dart:async';
import 'package:flutter/material.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/cloud_functions_service.dart';

class CoachDashboardViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();
  final CloudFunctionsService _functions = CloudFunctionsService();

  String? get coachUid => _authRepo.currentUser?.uid;

  // State for athletes data
  List<Map<String, dynamic>> _athletes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get athletes => _athletes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // State for loading indicators during add actions
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Fetch athletes using Cloud Functions
  Future<void> fetchAthletes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _athletes = await _functions.getAthletes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _athletes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Logic: Add New Athlete ---
  Future<bool> addNewAthlete(String name, String pin) async {
    if (coachUid == null) return false;
    _setProcessing(true);
    try {
      await _dbRepo.addNewAthlete(
        coachUid: coachUid!,
        name: name,
        pin: pin,
      );
      
      // Refresh the athlete list
      await fetchAthletes();
      
      return true;
    } catch (e) {
      debugPrint("Error adding athlete: $e");
      _setProcessing(false);
      return false;
    }
  }

  // --- Logic: Mass Assign (Concept) ---
  // In a full implementation, you would pass a list of athlete IDs.
  // For now, this is a placeholder or you can implement a "Assign to All" here.
  
  Future<void> logout() async {
    try {
      await _authRepo.signOut();
    } catch (e) {
      debugPrint("Error logging out: $e");
    }
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}