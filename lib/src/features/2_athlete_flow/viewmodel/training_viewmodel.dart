import 'package:flutter/material.dart';
import '../../../core/services/database_repository.dart';

class TrainingViewModel extends ChangeNotifier {
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 1. Make coachUid nullable
  String? _coachUid;
  
  // 2. Add a helper to check if connected
  bool get hasCoach => _coachUid != null;

  void initialize(Map<String, dynamic> athleteData) {
    // Safely retrieve coachUid (it might be null)
    _coachUid = athleteData['coachUid'];
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchCoachDrills() {
    // 3. Prevent API call if no coach
    if (_coachUid == null) {
      return Future.value([]); 
    }
    return _dbRepo.getDrillsForCoach(_coachUid!);
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