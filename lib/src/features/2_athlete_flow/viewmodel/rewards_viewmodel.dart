import 'dart:async';
import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Rewards View.
*/
class RewardsViewModel extends ChangeNotifier {
  final DatabaseRepository _dbRepo = DatabaseRepository();
  late String _athleteId;

  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }

  // --- REPLACED STREAM WITH FUTURE ---
  
  // Fetch athlete data to update Level/XP and check unlocks
  Future<Map<String, dynamic>?> fetchAthleteProfile() {
    return _dbRepo.getAthleteDocument(_athleteId);
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