import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Review Submission View.
*/
class ReviewSubmissionViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late Map<String, dynamic> _logData;
  late String _athleteId;
  late String _logId;

  VideoPlayerController? coachVideoController;
  VideoPlayerController? athleteVideoController;

  bool _isInitializing = true;
  bool _isSubmitting = false;

  final TextEditingController feedbackController = TextEditingController();

  // 3. Getters
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  String get drillName => _logData['drill'] ?? 'Submission';

  // 4. Initialization
  void initialize(Map<String, dynamic> routeArgs) {
    _logData = routeArgs['logData'] as Map<String, dynamic>;
    _athleteId = routeArgs['athleteId'] as String;
    _logId = routeArgs['logId'] as String;
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    try {
      final String coachUrl = _logData['coachVideoUrl'] ?? '';
      final String athleteUrl = _logData['athleteVideoUrl'] ?? '';

      if (coachUrl.isEmpty || athleteUrl.isEmpty) {
        throw Exception('Video URLs not found.');
      }

      coachVideoController =
          VideoPlayerController.networkUrl(Uri.parse(coachUrl));
      athleteVideoController =
          VideoPlayerController.networkUrl(Uri.parse(athleteUrl));

      await coachVideoController?.initialize();
      await athleteVideoController?.initialize();

      _isInitializing = false;
      notifyListeners();

      coachVideoController?.play();
      athleteVideoController?.play();
    } catch (e) {
      _isInitializing = false;
      notifyListeners();
      // Handle error (e.g., set an error state)
      debugPrint('Failed to load videos: $e');
    }
  }

  // 5. Logic
  Future<bool> submitReview(bool isApproved) async {
    _setSubmitting(true);
    try {
      await _dbRepo.submitReview(
        athleteId: _athleteId,
        logId: _logId,
        isApproved: isApproved,
        feedback: feedbackController.text.trim(),
      );
      _setSubmitting(false);
      return true; // Success
    } catch (e) {
      _setSubmitting(false);
      return false; // Failed
    }
  }

  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  // 6. Clean up
  @override
  void dispose() {
    coachVideoController?.dispose();
    athleteVideoController?.dispose();
    feedbackController.dispose();
    super.dispose();
  }
}