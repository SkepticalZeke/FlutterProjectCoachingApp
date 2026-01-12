import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Splash View.
*/
class SplashViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  // Sign out any existing session and return the initial route
  Future<String> getInitialRoute() async {
    // Always sign out when app starts to remove persistent login
    await _authRepo.signOut();

    // Add a delay to show the splash screen longer
    await Future.delayed(const Duration(seconds: 3));

    // Always go to role selection - no auto-login
    return '/role-selection';
  }
}