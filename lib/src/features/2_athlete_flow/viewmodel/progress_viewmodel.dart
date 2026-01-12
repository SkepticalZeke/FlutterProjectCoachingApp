import 'dart:async';
import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Progress View.
*/
class ProgressViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late String _athleteId;

  // 3. Getters for Streams
  // Provides a live stream of the athlete's main document (for skills)
  Future<Map<String, dynamic>?> fetchAthleteProfile() {
    return _dbRepo.getAthleteDocument(_athleteId);
  }

  // Provides a live stream of the athlete's logs (for calendar)
  Future<List<Map<String, dynamic>>> fetchAthleteLogs() {
    return _dbRepo.getAthleteLogs(_athleteId);
  }

  // 4. Initialization
  // This is called by the View to set the athleteId
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }
}