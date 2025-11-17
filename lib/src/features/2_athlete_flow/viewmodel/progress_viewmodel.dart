import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Stream<DocumentSnapshot> get athleteStream {
    return _dbRepo.getAthleteDocumentStream(_athleteId);
  }

  // Provides a live stream of the athlete's logs (for calendar)
  Stream<QuerySnapshot> get athleteLogsStream {
    return _dbRepo.getAthleteLogsStream(_athleteId);
  }

  // 4. Initialization
  // This is called by the View to set the athleteId
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }
}