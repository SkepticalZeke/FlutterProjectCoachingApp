import 'package:flutter/material.dart';
import '../../../core/services/cloud_functions_service.dart';

/*
  VIEW-MODEL for Athlete Management
  Uses Cloud Functions for CRUD operations on athletes
*/
class AthleteManagementViewModel extends ChangeNotifier {
  final CloudFunctionsService _functions = CloudFunctionsService();

  // State
  List<Map<String, dynamic>> _athletes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get athletes => _athletes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========================================================================
  // Fetch Athletes
  // ========================================================================

  /// Get all athletes for the current coach
  Future<void> fetchAthletes() async {
    _setLoading(true);
    try {
      _athletes = await _functions.getAthletes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching athletes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single athlete by ID
  Future<Map<String, dynamic>?> getAthlete(String athleteId) async {
    try {
      return await _functions.getAthlete(athleteId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching athlete: $e');
      notifyListeners();
      return null;
    }
  }

  // ========================================================================
  // Create Athlete
  // ========================================================================

  /// Create a new athlete using Cloud Function
  Future<String?> createAthlete({
    required String name,
    required String email,
    required String pin,
    required String coachId,
  }) async {
    _setLoading(true);
    try {
      final athleteId = await _functions.createAthlete(
        name: name,
        pin: pin,
        coachId: coachId,
      );

      // Refresh the list
      await fetchAthletes();

      return athleteId;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating athlete: $e');
      _setLoading(false);
      return null;
    }
  }

  // ========================================================================
  // Update Athlete
  // ========================================================================

  /// Update athlete information
  Future<bool> updateAthlete({
    required String athleteId,
    required Map<String, dynamic> updates,
  }) async {
    _setLoading(true);
    try {
      await _functions.updateAthlete(
        athleteId: athleteId,
        updates: updates,
      );

      // Refresh the list
      await fetchAthletes();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating athlete: $e');
      _setLoading(false);
      return false;
    }
  }

  // ========================================================================
  // Delete Athlete
  // ========================================================================

  /// Delete an athlete (admin only)
  Future<bool> deleteAthlete(String athleteId) async {
    _setLoading(true);
    try {
      await _functions.deleteAthlete(athleteId);

      // Remove from local list
      _athletes.removeWhere((athlete) => athlete['id'] == athleteId);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting athlete: $e');
      _setLoading(false);
      return false;
    }
  }

  // ========================================================================
  // Helper Methods
  // ========================================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
