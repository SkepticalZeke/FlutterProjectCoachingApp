import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
// Import our Models
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Create Drill View.
*/
class CreateDrillViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();
  final StorageRepository _storageRepo = StorageRepository();

  // 2. State
  bool _isLoading = false;
  String _skillFocus = 'General';
  double _xpGained = 50;
  XFile? _videoFile;
  VideoPlayerController? _videoController;

  // 3. Getters
  bool get isLoading => _isLoading;
  String get skillFocus => _skillFocus;
  double get xpGained => _xpGained;
  VideoPlayerController? get videoController => _videoController;

  // 4. Logic Functions (called by View)
  Future<void> pickVideo() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        _videoFile = pickedFile;
        _initializeVideoPlayer();
        notifyListeners();
      }
    } catch (e) {
      // Handle error (e.g., set an error message state)
      debugPrint("Error picking video: $e");
    }
  }

  void _initializeVideoPlayer() {
    if (_videoFile == null) return;
    _videoController?.dispose(); // Dispose old controller
    _videoController = VideoPlayerController.file(File(_videoFile!.path))
      ..initialize().then((_) {
        _videoController?.play();
        notifyListeners();
      });
  }

  // 5. State Setters (called by View)
  void setSkillFocus(String newValue) {
    _skillFocus = newValue;
    notifyListeners();
  }

  void setXp(double newValue) {
    _xpGained = newValue;
    notifyListeners();
  }

  // 6. Main Save Logic
  Future<bool> saveDrill({
    required String name,
    required String goal,
  }) async {
    if (_videoFile == null) {
      // In a real app, set an error state
      return false;
    }

    _setLoading(true);

    try {
      // 1. Upload Video
      final file = File(_videoFile!.path);
      final String downloadUrl =
          await _storageRepo.uploadCoachDrillVideo(file);

      // 2. Save Drill Data
      await _dbRepo.createCoachDrill(
        name: name,
        goal: goal,
        skillFocus: _skillFocus,
        xp: _xpGained,
        videoUrl: downloadUrl,
      );

      _setLoading(false);
      return true; // Success
    } catch (e) {
      // Handle error
      _setLoading(false);
      return false; // Failed
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 7. Clean up
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
