import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Splash View.
*/
class SplashViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  // Initialize the auth repository (includes session service)
  Future<void> init() async {
    await _authRepo.init();
  }

  // 1. Exposes the authentication state stream
  Stream<User?> get authStateChanges => _authRepo.authStateChanges;

  // 2. Logic to determine the initial route based on the user object and saved session
  Future<String> getInitialRoute(User? user) async {
    // First, check if there's a saved session (for users who logged in before closing the app)
    if (await _authRepo.isSessionActive()) {
      final String? userType = await _authRepo.getSavedUserType();
      
      if (userType == 'coach') {
        // Resume coach session
        return '/coach-home';
      } else if (userType == 'athlete') {
        // Resume athlete session - will be navigated with athlete data in SplashView
        return '/athlete-home';
      }
    }

    // If no saved session, check Firebase auth state
    if (user == null) {
      return '/role-selection';
    }
    // If a user exists (meaning a Coach is logged in via Firebase), go to the coach home.
    return '/coach-home';
  }

  /// Get saved athlete data if available (for resuming athlete session)
  Future<Map<String, dynamic>?> getSavedAthleteData() async {
    return await _authRepo.getSavedAthleteData();
  }
}