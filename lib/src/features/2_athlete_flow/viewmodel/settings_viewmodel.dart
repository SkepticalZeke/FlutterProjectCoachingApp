import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/auth_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Settings View.
*/
class SettingsViewModel extends ChangeNotifier {
  // 1. Repositories
  final AuthRepository _authRepo = AuthRepository();

  // 2. Logic
  Future<void> logout() async {
    try {
      // Call the repository to sign out
      await _authRepo.signOut();
    } catch (e) {
      // In a real app, you'd set an error state
      debugPrint("Error logging out: $e");
    }
  }
}