import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import our Model
import '../../../core/services/database_repository.dart';
import '../../../core/services/cloud_functions_service.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Coach Notifications View.
*/
class CoachNotificationsViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();
  final CloudFunctionsService _functions = CloudFunctionsService();

  // 2. State
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Provides a live stream of pending submissions
  Stream<QuerySnapshot> get pendingSubmissionsStream {
    try {
      return _dbRepo.getPendingSubmissionsStream();
    } catch (e) {
      debugPrint(e.toString());
      return const Stream.empty();
    }
  }

  // ========================================================================
  // NEW: Cloud Function Methods
  // ========================================================================

  /// Fetch all notifications from Cloud Function
  Future<void> fetchNotifications() async {
    _setLoading(true);
    try {
      _notifications = await _functions.getNotifications();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mark a single notification as read
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      await _functions.markNotificationRead(notificationId);
      // Refresh the list
      await fetchNotifications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error marking notification as read: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsRead() async {
    _setLoading(true);
    try {
      await _functions.markAllNotificationsRead();
      // Refresh the list
      await fetchNotifications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications() async {
    _setLoading(true);
    try {
      await _functions.clearNotifications();
      _notifications = [];
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error clearing notifications: $e');
      _setLoading(false);
      return false;
    }
  }

  // Helper method
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}