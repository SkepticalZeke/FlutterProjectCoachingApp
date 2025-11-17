import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Models
import '../../../core/services/auth_repository.dart';
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Dashboard View.
*/
class CoachDashboardViewModel extends ChangeNotifier {
  // 1. Repositories
  final AuthRepository _authRepo = AuthRepository();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. Getters for View
  // Gets the UID of the currently logged-in coach
  String? get coachUid => _authRepo.currentUser?.uid;

  // Provides a live stream of athletes for the View to listen to
  Stream<QuerySnapshot> get athletesStream {
    if (coachUid == null) {
      // Return an empty stream if the user is somehow logged out
      return const Stream.empty();
    }
    return _dbRepo.getAthletesStream(coachUid!);
  }

  // 3. Logic
  Future<void> logout() async {
    try {
      await _authRepo.signOut();
    } catch (e) {
      // In a real app, you'd set an error state here
      debugPrint("Error logging out: $e");
    }
  }
}