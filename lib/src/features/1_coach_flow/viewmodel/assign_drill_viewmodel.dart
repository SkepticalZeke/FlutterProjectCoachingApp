import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Assign Drill View.
*/
class AssignDrillViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  bool _isLoading = false;

  // 3. Getters
  bool get isLoading => _isLoading;

  // Provides a live stream of the coach's custom drills
Future<List<Map<String, dynamic>>> fetchCoachDrills() {
    return _dbRepo.getCoachDrills();
  }

  // 4. Logic
  Future<bool> assignDrill({
    required String athleteId,
    required Map<String, dynamic> drillData,
  }) async {
    _setLoading(true);
    try {
      await _dbRepo.assignDrillToAthlete(
        athleteId: athleteId,
        drillData: drillData,
      );
      _setLoading(false);
      return true; // Success
    } catch (e) {
      _setLoading(false);
      return false; // Failed
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}