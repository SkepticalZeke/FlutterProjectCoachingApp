import 'dart:async';
import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Athlete Detail View.
*/
class CoachAthleteDetailViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  bool _isSaving = false;
  String _currentDifficulty = 'Easy';
  String _currentSkillFocus = 'General';

  // 3. Getters
  bool get isSaving => _isSaving;
  String get currentDifficulty => _currentDifficulty;
  String get currentSkillFocus => _currentSkillFocus;

  // 4. Initialization
  // This is called by the View to set the initial state
  void initialize(Map<String, dynamic> athleteData) {
    _currentDifficulty = athleteData['difficulty'] ?? 'Easy';
    _currentSkillFocus = athleteData['skill_focus'] ?? 'General';
  }

  // 5. Logic
  Future<bool> saveRoutineSettings({
    required String athleteId,
    required String notes,
  }) async {
    _setSaving(true);
    try {
      await _dbRepo.updateAthleteDetails(
        athleteId,
        _currentDifficulty,
        _currentSkillFocus,
        notes,
      );
      _setSaving(false);
      return true; // Success
    } catch (e) {
      _setSaving(false);
      return false; // Failed
    }
  }

  Future<bool> addRestDay(String athleteId) async {
    try {
      await _dbRepo.addRestDay(athleteId);
      return true; // Success
    } catch (e) {
      return false; // Failed
    }
  }

  // 6. Get Stream
  Future<List<Map<String, dynamic>>> fetchAthleteLogs(String athleteId) {
    return _dbRepo.getAthleteLogs(athleteId);
  }

  // 7. State Setters (used by the View)
  void setDifficulty(String newValue) {
    _currentDifficulty = newValue;
    notifyListeners();
  }

  void setSkillFocus(String newValue) {
    _currentSkillFocus = newValue;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }
}