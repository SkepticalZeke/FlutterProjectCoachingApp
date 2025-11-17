import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Notifications View.
*/
class CoachNotificationsViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. Getters for Streams
  // Provides a live stream of pending submissions
  Stream<QuerySnapshot> get pendingSubmissionsStream {
    try {
      return _dbRepo.getPendingSubmissionsStream();
    } catch (e) {
      debugPrint(e.toString());
      return const Stream.empty();
    }
  }
}