import 'package:flutter/material.dart';
import '../../../core/services/cloud_functions_service.dart';

/*
  VIEW-MODEL for Drill Management
  Uses Cloud Functions for drill CRUD operations
*/
class DrillManagementViewModel extends ChangeNotifier {
  final CloudFunctionsService _functions = CloudFunctionsService();

  // State
  List<Map<String, dynamic>> _drills = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get drills => _drills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========================================================================
  // Fetch Drills
  // ========================================================================

  /// Get all drills (filtered by role on backend)
  Future<void> fetchDrills({String? status}) async {
    _setLoading(true);
    try {
      _drills = await _functions.getDrills(status: status);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching drills: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single drill by ID
  Future<Map<String, dynamic>?> getDrill(String drillId) async {
    try {
      return await _functions.getDrill(drillId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching drill: $e');
      notifyListeners();
      return null;
    }
  }

  // ========================================================================
  // Create Drill
  // ========================================================================

  /// Create/assign a new drill to an athlete (coach only)
  Future<String?> createDrill({
    required String title,
    required String athleteId,
    String? description,
    String? videoUrl,
    int? xp,
    String? skillFocus,
  }) async {
    _setLoading(true);
    try {
      final drillId = await _functions.createDrill(
        title: title,
        athleteId: athleteId,
        description: description,
        videoUrl: videoUrl,
        xp: xp,
        skillFocus: skillFocus,
      );

      // Refresh the list
      await fetchDrills();

      return drillId;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating drill: $e');
      _setLoading(false);
      return null;
    }
  }

  // ========================================================================
  // Submit Drill
  // ========================================================================

  /// Submit a drill for review (athlete only)
  Future<bool> submitDrill({
    required String drillId,
    String? videoUrl,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _functions.submitDrill(
        drillId: drillId,
        videoUrl: videoUrl,
        notes: notes,
      );

      // Refresh the list
      await fetchDrills();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error submitting drill: $e');
      _setLoading(false);
      return false;
    }
  }

  // ========================================================================
  // Review Drill
  // ========================================================================

  /// Review a drill (coach only)
  Future<bool> reviewDrill({
    required String drillId,
    required bool approved,
    String? feedback,
    int? rating,
  }) async {
    _setLoading(true);
    try {
      await _functions.reviewDrill(
        drillId: drillId,
        approved: approved,
        feedback: feedback,
        rating: rating,
      );

      // Refresh the list
      await fetchDrills();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error reviewing drill: $e');
      _setLoading(false);
      return false;
    }
  }

  // ========================================================================
  // Filter Drills
  // ========================================================================

  /// Filter drills by status
  Future<void> filterByStatus(String status) async {
    await fetchDrills(status: status);
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
