import 'dart:async';
import 'package:flutter/material.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

class CoachDashboardViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  String? get coachUid => _authRepo.currentUser?.uid;

  // Loading State
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // =======================================================
  // TAB 1: TEAM ROSTER LOGIC
  // =======================================================
  Future<List<Map<String, dynamic>>> fetchAthletes() async {
    if (coachUid == null) return [];
    return _dbRepo.getAthletes(coachUid!);
  }

  // NEW: Link Athlete by Code (Replaces old "Add Name/PIN")
  Future<bool> linkAthlete(String connectionCode) async {
    if (coachUid == null) return false;
    
    _setProcessing(true);
    try {
      await _dbRepo.linkAthlete(connectionCode);
      _setProcessing(false);
      return true; // Success
    } catch (e) {
      debugPrint("Error linking athlete: $e");
      _setProcessing(false);
      return false; // Failed
    }
  }

  // =======================================================
  // TAB 2: DRILL LIBRARY LOGIC
  // =======================================================
  Future<List<Map<String, dynamic>>> fetchCoachDrills() async {
    if (coachUid == null) return [];
    return _dbRepo.getCoachDrills();
  }

  // =======================================================
  // TAB 3: NOTIFICATIONS LOGIC
  // =======================================================
  Future<List<Map<String, dynamic>>> fetchPendingSubmissions() async {
    // The repo handles finding pending logs for this coach
    return _dbRepo.getPendingSubmissions();
  }

  // =======================================================
  // AUTH LOGIC
  // =======================================================
  Future<void> logout() async {
    await _authRepo.signOut();
  }

  void _setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }
}