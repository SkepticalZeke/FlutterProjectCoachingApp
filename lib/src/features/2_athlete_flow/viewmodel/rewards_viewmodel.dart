import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Rewards View.
*/
class RewardsViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late String _athleteId;

  // 3. Getters for Streams
  // Provides a live stream of the athlete's main document (for level/xp)
  Stream<DocumentSnapshot> get athleteStream {
    return _dbRepo.getAthleteDocumentStream(_athleteId);
  }

  // 4. Initialization
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }

  // 5. Logic & Data for Achievements
  // (This is mock data for now, but the logic to check
  // 'unlocked' status can be expanded here in the ViewModel)
  final List<Map<String, dynamic>> achievements = const [
    // Streaks
    {
      'name': '3-Day Streak',
      'unlocked': true,
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
    {
      'name': '7-Day Champion',
      'unlocked': true,
      'icon': Icons.local_fire_department,
      'color': Colors.red
    },
    {
      'name': '14-Day Legend',
      'unlocked': false,
      'icon': Icons.local_fire_department,
      'color': Colors.grey
    },
    // Effort & Milestones
    {
      'name': 'First Drill',
      'unlocked': true,
      'icon': Icons.star_border,
      'color': Colors.yellow
    },
    {
      'name': '1,000 Total XP',
      'unlocked': true,
      'icon': Icons.military_tech,
      'color': Colors.blue
    },
    {
      'name': '5,000 Total XP',
      'unlocked': false,
      'icon': Icons.military_tech,
      'color': Colors.grey
    },
    // Skill Badges
    {
      'name': 'Agility Ace',
      'unlocked': true,
      'icon': Icons.speed,
      'color': Colors.blue
    },
    {
      'name': 'Strength Star',
      'unlocked': false,
      'icon': Icons.fitness_center,
      'color': Colors.grey
    },
    {
      'name': 'Cardio King',
      'unlocked': false,
      'icon': Icons.directions_run,
      'color': Colors.grey
    },
  ];
}