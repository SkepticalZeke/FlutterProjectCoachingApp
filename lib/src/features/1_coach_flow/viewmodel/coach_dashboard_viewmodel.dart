import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

class CoachDashboardViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  String? get coachUid => _authRepo.currentUser?.uid;

  // State for loading indicators during add actions
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Stream<QuerySnapshot> get athletesStream {
    if (coachUid == null) return const Stream.empty();
    return _dbRepo.getAthletesStream(coachUid!);
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