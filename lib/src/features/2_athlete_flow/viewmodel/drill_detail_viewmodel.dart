import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
// Import our Models
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Drill Detail View.
*/
class DrillDetailViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();
  final StorageRepository _storageRepo = StorageRepository();

  // 2. Data from View
  late String _athleteId;
  late String _drillId;
  late Map<String, dynamic> _drillData;

  // 3. State
  String drillName = 'Drill';
  String drillGoal = 'Complete the drill.';
  String coachVideoUrl = '';

  Timer? _timer;
  int _currentTime = 60;
  bool _isRunning = false;
  bool _isCompleted = false;
  bool _isUploading = false;

  VideoPlayerController? coachVideoController;
  bool isCoachVideoInitialized = false;

  XFile? athleteVideoFile;
  VideoPlayerController? athleteVideoController;

  // 4. Getters for the View
  int get currentTime => _currentTime;
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  bool get isUploading => _isUploading;
  Map<String, dynamic> get drillData => _drillData; // Expose drillData

  // 5. Initialization Logic (called by View's initState)
  void initialize(Map<String, dynamic> routeArgs) {
    try {
      _drillData = routeArgs['drillData'] as Map<String, dynamic>? ?? {};
      _athleteId = routeArgs['athleteId'] as String? ?? '';
      _drillId = routeArgs['drillId'] as String? ?? '';

      drillName = _drillData['name'] ?? 'Drill';
      drillGoal = _drillData['goal'] ?? 'Complete the drill.';
      _currentTime = (_drillData['time'] as int?) ?? 60;
      coachVideoUrl = _drillData['videoUrl'] as String? ?? '';

      if (coachVideoUrl.isNotEmpty) {
        _initializeCoachVideoPlayer();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing drill detail: $e');
      notifyListeners();
    }
  }

  void _initializeCoachVideoPlayer() {
    coachVideoController =
        VideoPlayerController.networkUrl(Uri.parse(coachVideoUrl))
          ..initialize().then((_) {
            isCoachVideoInitialized = true;
            coachVideoController?.setLooping(true);
            coachVideoController?.play();
            notifyListeners();
          });
  }

  void _initializeAthleteVideoPlayer() {
    if (athleteVideoFile == null) return;
    athleteVideoController?.dispose();
    athleteVideoController =
        VideoPlayerController.file(File(athleteVideoFile!.path))
          ..initialize().then((_) {
            athleteVideoController?.play();
            notifyListeners();
          });
  }

  // 6. Logic Functions (called by View)
  Future<void> pickAthleteVideo() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        athleteVideoFile = pickedFile;
        _initializeAthleteVideoPlayer();
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  void startTimer() {
    if (_isCompleted) resetTimer();
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        _currentTime--;
      } else {
        _timer?.cancel();
        _isRunning = false;
      }
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _currentTime = _drillData['time'] ?? 60;
    _isCompleted = false;
    notifyListeners();
  }

  // This is the main logic
  Future<bool> markAsDone() async {
    if (athleteVideoFile == null) {
      // In a real app, you'd set an error message
      return false;
    }

    stopTimer();
    _isCompleted = true;
    _isUploading = true;
    notifyListeners();

    try {
      // 1. Upload Video
      final file = File(athleteVideoFile!.path);
      final String athleteVideoUrl =
          await _storageRepo.uploadSubmissionVideo(file, _athleteId);

      // 2. Save Data
      await _dbRepo.completeDrill(
        athleteId: _athleteId,
        drillId: _drillId,
        drillName: drillName,
        xpGained: _drillData['xp'] ?? 50,
        coachVideoUrl: coachVideoUrl,
        athleteVideoUrl: athleteVideoUrl,
        coachUid: _drillData['coachUid'] as String? ?? '', // Handle null safely
      );

      _isUploading = false;
      notifyListeners();
      return true; // Success!
    } catch (e) {
      _isCompleted = false; // Allow user to try again
      _isUploading = false;
      notifyListeners();
      return false; // Failed
    }
  }

  // 7. Clean up
  @override
  void dispose() {
    _timer?.cancel();
    coachVideoController?.dispose();
    athleteVideoController?.dispose();
    super.dispose();
  }
}