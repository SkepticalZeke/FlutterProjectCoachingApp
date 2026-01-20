import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Drill Library View.
  Manages fetching, editing, and deleting drills.
*/
class DrillLibraryViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  bool _isLoading = false;
  List<Map<String, dynamic>> _drills = [];
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get drills => _drills;
  String? get errorMessage => _errorMessage;

  // 4. Initialize - Load drills on creation
  Future<void> init() async {
    await loadDrills();
  }

  // 5. Load all drills for the current coach
  Future<void> loadDrills() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _drills = await _dbRepo.getCoachDrills();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load drills: $e';
      debugPrint(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // 6. Delete a drill
  Future<bool> deleteDrill(String drillId) async {
    try {
      await _dbRepo.deleteDrill(drillId);
      _drills.removeWhere((drill) => drill['id'] == drillId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete drill: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  // 7. Get a single drill for editing
  Future<Map<String, dynamic>?> getDrill(String drillId) async {
    try {
      return await _dbRepo.getDrill(drillId);
    } catch (e) {
      _errorMessage = 'Failed to fetch drill details: $e';
      debugPrint(_errorMessage);
      return null;
    }
  }

  // 8. Update drill metadata (name, goal, etc.) - no video upload
  Future<bool> updateDrill({
    required String drillId,
    required String name,
    required String goal,
    required String skillFocus,
    required double xp,
  }) async {
    try {
      await _dbRepo.updateDrill(
        drillId: drillId,
        name: name,
        goal: goal,
        skillFocus: skillFocus,
        xp: xp,
      );

      // Update local list
      final index = _drills.indexWhere((drill) => drill['id'] == drillId);
      if (index != -1) {
        _drills[index]['name'] = name;
        _drills[index]['goal'] = goal;
        _drills[index]['skillFocus'] = skillFocus;
        _drills[index]['xp'] = xp;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update drill: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
