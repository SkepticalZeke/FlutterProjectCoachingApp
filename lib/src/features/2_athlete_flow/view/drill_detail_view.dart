import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // Needed for FontFeature
import 'package:video_player/video_player.dart';
// Import the new ViewModel
import '../viewmodel/drill_detail_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class DrillDetailView extends StatefulWidget {
  final Map<String, dynamic> routeArgs;
  const DrillDetailView({super.key, required this.routeArgs});

  @override
  State<DrillDetailView> createState() => _DrillDetailViewState();
}

class _DrillDetailViewState extends State<DrillDetailView> {
  // 1. The View owns its ViewModel
  final _viewModel = DrillDetailViewModel();

  @override
  void initState() {
    super.initState();
    // 2. Initialize the ViewModel
    _viewModel.initialize(widget.routeArgs);
    // 3. Listen for changes
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    // 4. Clean up
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose(); // Also dispose the ViewModel
    super.dispose();
  }

  // 5. Rebuild the UI when the ViewModel changes
  void _onViewModelChanged() {
    setState(() {});
  }

  // 6. "Mark as Done" now calls the ViewModel
  void _markAsDone() async {
    bool success = await _viewModel.markAsDone();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Drill Submitted for Review! +50 XP!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Submission failed. Please check video and try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // 7. Build Action Button now reads from ViewModel
  Widget _buildActionButton() {
    if (_viewModel.isCompleted) {
      return ElevatedButton.icon(
        onPressed: _viewModel.resetTimer, // Call ViewModel
        icon: const Icon(Icons.refresh),
        label: const Text('Try Again'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (_viewModel.isRunning) {
      return ElevatedButton.icon(
        onPressed: _viewModel.stopTimer, // Call ViewModel
        icon: const Icon(Icons.pause),
        label: const Text('Pause Drill'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _viewModel.startTimer, // Call ViewModel
          icon: const Icon(Icons.play_arrow),
          label: Text(
            _viewModel.currentTime ==
                    (_viewModel.drillData['time'] as int? ?? 60)
                ? 'Start Training'
                : 'Resume',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
  }

  // 8. The rest of the build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _viewModel.drillName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // DARK BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Coach's Video Player ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.1),
                        child: const Text(
                          "Coach's Example",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_viewModel.isCoachVideoInitialized)
                              AspectRatio(
                                aspectRatio: _viewModel
                                    .coachVideoController!.value.aspectRatio,
                                child: VideoPlayer(
                                    _viewModel.coachVideoController!),
                              )
                            else
                              Center(
                                child: _viewModel.coachVideoUrl.isEmpty
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.videocam_off,
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              size: 40),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No example video',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                          ),
                                        ],
                                      )
                                    : const CircularProgressIndicator(
                                        color: Colors.white),
                              ),
                            if (_viewModel.isCoachVideoInitialized)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _viewModel
                                            .coachVideoController!.value.isPlaying
                                        ? _viewModel.coachVideoController!
                                            .pause()
                                        : _viewModel.coachVideoController!
                                            .play();
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent, // Touch target
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _viewModel.coachVideoController!.value
                                                .isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Drill Instructions ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Goal',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _viewModel.drillGoal,
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade400,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Timer/Counter Display ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Time Remaining',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_viewModel.currentTime),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _viewModel.currentTime < 10 &&
                                  _viewModel.currentTime > 0
                              ? Colors.red
                              : theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- Action Buttons ---
                Center(child: _buildActionButton()),
                const SizedBox(height: 30),

                // --- Athlete's Submission Section ---
                if (!_viewModel.isCompleted) ...[
                  Divider(color: Colors.grey.shade700),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Submission',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Video Picker/Preview
                  GestureDetector(
                    onTap: _viewModel.pickAthleteVideo,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.grey.shade700,
                            style: BorderStyle.solid),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_viewModel.athleteVideoController != null &&
                              _viewModel
                                  .athleteVideoController!.value.isInitialized)
                            AspectRatio(
                              aspectRatio: _viewModel
                                  .athleteVideoController!.value.aspectRatio,
                              child: VideoPlayer(
                                  _viewModel.athleteVideoController!),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 48, color: theme.primaryColor),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to Upload Video',
                                  style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),

                          // If video is selected, show change button overlay
                          if (_viewModel.athleteVideoFile != null)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit, size: 20, color: theme.primaryColor),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Mark as Done Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _viewModel.isUploading ? null : _markAsDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _viewModel.isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline),
                                SizedBox(width: 10),
                                Text(
                                  'Submit for Review',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper, can be moved to a utils file
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}