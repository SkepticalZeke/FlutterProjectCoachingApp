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

  // 1. Exposes the authentication state stream
  Stream<User?> get authStateChanges => _authRepo.authStateChanges;

  // 2. Logic to determine the initial route based on the user object
  String getInitialRoute(User? user) {
    // If user is null, go to the main login page for athletes.
    if (user == null) {
      return '/login';
    }
    // If a user exists (meaning a Coach is logged in), go to the coach home.
    return '/coach-home';
  }
}