import 'dart:async';
import 'package:flutter/material.dart';
// Import our Models
import '../../../core/services/api_service.dart';
import '../../../core/services/database_repository.dart';

class CoachDashboardViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  String? get coachUid => _api.coachUid;

  // State for loading indicators during add actions
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<List<Map<String, dynamic>>> fetchAthletes() async {
    if (coachUid == null) return [];
    return _dbRepo.getAthletes(coachUid!);
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
      _setProcessing(false);
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
      await _api.clearToken();
    } catch (e) {
      debugPrint("Error logging out: $e");
    }
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}