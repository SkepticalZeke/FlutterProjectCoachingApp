import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete's Training View.
*/
class TrainingViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late String _coachUid;

  // 3. Getters for Streams
  // Provides a live stream of the coach's custom drills
  Stream<QuerySnapshot> get coachDrillsStream {
    try {
      return _dbRepo.getDrillsForCoach(_coachUid);
    } catch (e) {
      // Return an empty stream if there's an error
      debugPrint(e.toString());
      return const Stream.empty();
    }
  }

  // 4. Initialization
  // This is called by the View to set the coachId
  void initialize(Map<String, dynamic> athleteData) {
    _coachUid = athleteData['coachUid'];
  }

  // 5. Mock Data for "Default" Drills
  final List<Map<String, dynamic>> defaultDrills = const [
    {
      'name': 'Bodyweight Strength',
      'goal': 'Complete 3 sets of 15 push-ups and 20 squats.',
      'time': 120,
      'category': 'Strength',
      'iconData': 0xe28f, // fitness_center
      'color': Colors.red,
      'xp': 50,
    },
    {
      'name': 'High-Intensity Sprints',
      'goal': 'Perform 10 sprints of 30 seconds each.',
      'time': 300,
      'category': 'Cardio',
      // ⭐️⭐️ FIX: Changed from 'timer' (0xe675) to 'directions_run' (0xe1d1) ⭐️⭐️
      'iconData': 0xe1d1,
      'color': Colors.orange,
      'xp': 75,
    },
    {
      'name': 'Stretching & Cool Down',
      'goal': 'Hold each stretch for 30 seconds.',
      'time': 120,
      'category': 'Flexibility',
      'iconData': 0xe585, // self_improvement
      'color': Colors.purple,
      'xp': 25,
    },
  ];
}