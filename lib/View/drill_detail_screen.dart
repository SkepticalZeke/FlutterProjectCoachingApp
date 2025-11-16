import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io'; // ⭐️ ADDED for File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ⭐️ ADDED for Storage
import 'package:image_picker/image_picker.dart'; // ⭐️ ADDED for ImagePicker
import 'package:video_player/video_player.dart'; // ⭐️ ADDED for VideoPlayer

class DrillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> routeArgs;
  const DrillDetailScreen({super.key, required this.routeArgs});

  @override
  State<DrillDetailScreen> createState() => _DrillDetailScreenState();
}

class _DrillDetailScreenState extends State<DrillDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // ⭐️ ADDED

  // Drill data
  late String drillName;
  late String drillGoal;
  late int initialTimeSeconds;
  late String athleteId;
  late String drillId;
  late Map<String, dynamic> drillData;
  late String _coachVideoUrl; // ⭐️ ADDED

  // Timer State
  late int _currentTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;

  // ⭐️ ADDED: Coach's Video Player
  VideoPlayerController? _coachVideoController;
  bool _isCoachVideoInitialized = false;

  // ⭐️ ADDED: Athlete's Video Submission
  final ImagePicker _picker = ImagePicker();
  XFile? _athleteVideoFile;
  VideoPlayerController? _athleteVideoController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Unpack route arguments
    drillData = widget.routeArgs['drillData'] as Map<String, dynamic>;
    athleteId = widget.routeArgs['athleteId'] as String;
    drillId = widget.routeArgs['drillId'] as String;

    // Initialize drill data
    drillName = drillData['name'] ?? 'Drill';
    drillGoal = drillData['goal'] ?? 'Complete the drill.';
    initialTimeSeconds = drillData['time'] ?? 60;
    _currentTime = initialTimeSeconds;

    // ⭐️ ADDED: Initialize Coach's Video
    _coachVideoUrl = drillData['videoUrl'] ?? '';
    if (_coachVideoUrl.isNotEmpty) {
      _initializeCoachVideoPlayer();
    }
  }

  // ⭐️ NEW: Initialize Coach's video player
  void _initializeCoachVideoPlayer() {
    _coachVideoController =
        VideoPlayerController.networkUrl(Uri.parse(_coachVideoUrl))
          ..initialize().then((_) {
            setState(() {
              _isCoachVideoInitialized = true;
            });
            _coachVideoController?.setLooping(true);
            _coachVideoController?.play();
          });
  }

  // ⭐️ NEW: Initialize Athlete's video player for preview
  void _initializeAthleteVideoPlayer() {
    if (_athleteVideoFile == null) return;
    _athleteVideoController?.dispose();
    _athleteVideoController =
        VideoPlayerController.file(File(_athleteVideoFile!.path))
          ..initialize().then((_) {
            setState(() {}); // Update UI
            _athleteVideoController?.play();
          });
  }

  // ⭐️ NEW: Function to pick athlete's submission video
  Future<void> _pickAthleteVideo() async {
    try {
      final XFile? pickedFile =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _athleteVideoFile = pickedFile;
        });
        _initializeAthleteVideoPlayer();
      }
    } catch (e) {
      _showErrorSnackBar("Error picking video: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coachVideoController?.dispose();
    _athleteVideoController?.dispose();
    super.dispose();
  }

  // --- Timer logic (unchanged) ---
  void _startTimer() {
    if (_isCompleted) {
      _resetTimer();
    }
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        setState(() {
          _currentTime--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Time\'s up! Try again or mark as done.')),
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _currentTime = initialTimeSeconds;
      _isCompleted = false;
    });
  }

  // ⭐️ UPDATED: Mark as Done now uploads video
  void _markAsDone() async {
    if (_athleteVideoFile == null) {
      _showErrorSnackBar('Please upload your submission video first.');
      return;
    }

    _stopTimer();
    setState(() {
      _isCompleted = true; // Show "Try Again" button
      _isUploading = true; // Show loading indicator on "Mark as Done"
    });

    final int xpGained = drillData['xp'] ?? 50;
    String athleteVideoUrl = '';

    try {
      // 1. UPLOAD ATHLETE'S VIDEO
      final String videoFileName =
          '${athleteId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final File fileToUpload = File(_athleteVideoFile!.path);

      UploadTask uploadTask = _storage
          .ref('athlete_submissions/$athleteId/$videoFileName')
          .putFile(fileToUpload);

      TaskSnapshot snapshot = await uploadTask;
      athleteVideoUrl = await snapshot.ref.getDownloadURL();

      // 2. SAVE DATA TO FIRESTORE (as before)
      final athleteRef = _firestore.collection('athletes').doc(athleteId);
      final drillRef = athleteRef.collection('todayDrills').doc(drillId);
      final logRef = athleteRef.collection('logs').doc();

      DocumentSnapshot athleteDoc = await athleteRef.get();
      if (!athleteDoc.exists) throw Exception("Athlete document not found");

      final athleteData = athleteDoc.data() as Map<String, dynamic>;
      final String skillFocus = athleteData['skill_focus'] ?? 'General';
      final String skillProgressField = 'skillProgress.$skillFocus';

      WriteBatch batch = _firestore.batch();

      // Update the drill (add submission URL)
      batch.update(drillRef, {
        'completed': true,
        'status': 'Pending Review', // ⭐️ NEW: Set status for coach
        'athleteVideoUrl': athleteVideoUrl, // ⭐️ NEW
      });

      // Add a log entry (with submission URL)
      batch.set(logRef, {
        'drill': drillName,
        'status': 'Pending Review', // ⭐️ NEW
        'xp': xpGained,
        'date': FieldValue.serverTimestamp(),
        'skillFocus': skillFocus,
        'coachVideoUrl': _coachVideoUrl, // ⭐️ NEW
        'athleteVideoUrl': athleteVideoUrl, // ⭐️ NEW
      });

      // Increment XP
      batch.update(athleteRef, {
        'totalXp': FieldValue.increment(xpGained),
        'currentXp': FieldValue.increment(xpGained),
        skillProgressField: FieldValue.increment(xpGained),
      });

      // Commit
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Drill Submitted for Review! $xpGained XP awarded!',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green),
        );
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      _showErrorSnackBar(e.toString());
      setState(() {
        _isCompleted = false; // Allow user to try again
      });
    }

    setState(() {
      _isUploading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Widget _buildActionButton() {
    if (_isCompleted) {
      return ElevatedButton.icon(
        onPressed: _resetTimer,
        icon: const Icon(Icons.refresh),
        label: const Text('Try Again'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
      );
    }

    if (_isRunning) {
      return ElevatedButton.icon(
        onPressed: _stopTimer,
        icon: const Icon(Icons.pause),
        label: const Text('Pause Drill'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black, // Text on amber
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _currentTime == 0 ? _resetTimer : _startTimer,
        icon: Icon(_currentTime == 0 ? Icons.refresh : Icons.play_arrow),
        label: Text(_currentTime == 0
            ? 'Restart Timer'
            : (_currentTime == initialTimeSeconds ? 'Start Training' : 'Resume')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(drillName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⭐️ 1. COACH'S VIDEO PLAYER ⭐️
            Text(
              'Coach\'s Example',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ),
              child: Center(
                child: _isCoachVideoInitialized
                    ? AspectRatio(
                        aspectRatio: _coachVideoController!.value.aspectRatio,
                        child: VideoPlayer(_coachVideoController!),
                      )
                    : _coachVideoUrl.isEmpty
                        ? const Text('No example video for this drill.')
                        : const CircularProgressIndicator(),
              ),
            ),
            // ⭐️ ADDED: Play/Pause button for coach video ⭐️
            if (_isCoachVideoInitialized)
              IconButton(
                icon: Icon(_coachVideoController!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled),
                color: theme.colorScheme.primary,
                iconSize: 36,
                onPressed: () {
                  setState(() {
                    _coachVideoController!.value.isPlaying
                        ? _coachVideoController!.pause()
                        : _coachVideoController!.play();
                  });
                },
              ),
            const SizedBox(height: 30),

            // --- Drill Instructions ---
            Text(
              'Goal:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 5),
            Text(
              drillGoal,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // --- Timer/Counter Display ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Time Remaining',
                    style: TextStyle(
                        fontSize: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(_currentTime),
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: _currentTime < 10 && _currentTime > 0
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Action Buttons ---
            Center(child: _buildActionButton()),
            const SizedBox(height: 20),

            // ⭐️ 2. ATHLETE'S SUBMISSION SECTION ⭐️
            if (!_isCompleted) ...[
              Text(
                'Your Submission',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.2)),
                ),
                child: Center(
                  child: _athleteVideoController != null &&
                          _athleteVideoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio:
                              _athleteVideoController!.value.aspectRatio,
                          child: VideoPlayer(_athleteVideoController!),
                        )
                      : TextButton.icon(
                          icon: Icon(Icons.upload_file,
                              color: theme.colorScheme.primary),
                          label: Text(
                            'Select Your Video',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onPressed: _pickAthleteVideo,
                        ),
                ),
              ),
              if (_athleteVideoFile != null)
                TextButton(
                  onPressed: _pickAthleteVideo,
                  child: const Text('Change Video'),
                ),
              const SizedBox(height: 20),

              // ⭐️ 3. UPDATED MARK AS DONE BUTTON ⭐️
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _markAsDone,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                    _isUploading ? 'Submitting...' : 'I Finished! Submit for Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[400],
                  side: BorderSide(color: Colors.green[400]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
            const SizedBox(height: 40), // Added padding at the bottom
          ],
        ),
      ),
    );
  }
}