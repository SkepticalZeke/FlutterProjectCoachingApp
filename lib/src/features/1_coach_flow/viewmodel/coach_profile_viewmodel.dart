import 'package:flutter/material.dart';
import '../../../core/services/cloud_functions_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
  VIEWMODEL for Coach Profile
  Handles coach profile data and updates
*/
class CoachProfileViewModel extends ChangeNotifier {
  final CloudFunctionsService _functions = CloudFunctionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _coachData;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get coachData => _coachData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Fetch current coach's profile
  Future<void> fetchCoachProfile() async {
    if (currentUserId == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _coachData = await _functions.getCoach(currentUserId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _coachData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get coach statistics
  int get totalAthletes => _coachData?['totalAthletes'] ?? 0;
  int get totalDrills => _coachData?['totalDrills'] ?? 0;
  String get coachEmail => _coachData?['email'] ?? '';
  String get joinDate {
    final timestamp = _coachData?['createdAt'];
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Sign out the current coach
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
