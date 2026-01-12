import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Dashboard View.
*/
class AthleteDashboardViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late String _athleteId;

  String get athleteId => _athleteId;

  // 3. Initialization
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }

  // 4. DATA FETCHING (FUTURES)
  // These are the missing functions your View is looking for!

  // Fetch the athlete's profile (Level, XP, etc.)
  Future<Map<String, dynamic>?> getAthleteProfile() {
    return _dbRepo.getAthleteDocument(_athleteId);
  }

  // Fetch today's drills
  Future<List<Map<String, dynamic>>> getTodayDrills() {
    return _dbRepo.getTodayDrills(_athleteId);
  }
}