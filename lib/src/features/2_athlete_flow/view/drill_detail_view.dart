import 'package:flutter/material.dart';
import 'dart:async';
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
        const SnackBar(
            content: Text('Drill Submitted for Review! +50 XP!',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Submission failed. Please check video and try again.'),
            backgroundColor: Colors.red),
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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _viewModel.startTimer, // Call ViewModel
        icon: const Icon(Icons.play_arrow),
        label: Text(_viewModel.currentTime == (_viewModel.drillData['time'] as int? ?? 60)
            ? 'Start Training'
            : 'Resume'),
      );
    }
  }

  // 8. The rest of the build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewModel.drillName), // Read from ViewModel
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Coach's Video Player ---
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
                // Read from ViewModel
                child: _viewModel.isCoachVideoInitialized
                    ? AspectRatio(
                        aspectRatio:
                            _viewModel.coachVideoController!.value.aspectRatio,
                        child: VideoPlayer(_viewModel.coachVideoController!),
                      )
                    : _viewModel.coachVideoUrl.isEmpty
                        ? const Text('No example video for this drill.')
                        : const CircularProgressIndicator(),
              ),
            ),
            if (_viewModel.isCoachVideoInitialized)
              IconButton(
                // Read from ViewModel
                icon: Icon(_viewModel.coachVideoController!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled),
                color: theme.colorScheme.primary,
                iconSize: 36,
                onPressed: () {
                  setState(() {
                    _viewModel.coachVideoController!.value.isPlaying
                        ? _viewModel.coachVideoController!.pause()
                        : _viewModel.coachVideoController!.play();
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
              _viewModel.drillGoal, // Read from ViewModel
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
                    // Read from ViewModel
                    _formatTime(_viewModel.currentTime),
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: _viewModel.currentTime < 10 &&
                              _viewModel.currentTime > 0
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Action Buttons ---
            Center(child: _buildActionButton()), // Calls ViewModel
            const SizedBox(height: 20),

            // --- Athlete's Submission Section ---
            if (!_viewModel.isCompleted) ...[
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
                  // Read from ViewModel
                  child: _viewModel.athleteVideoController != null &&
                          _viewModel
                              .athleteVideoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _viewModel
                              .athleteVideoController!.value.aspectRatio,
                          child: VideoPlayer(_viewModel.athleteVideoController!),
                        )
                      : TextButton.icon(
                          icon: Icon(Icons.upload_file,
                              color: theme.colorScheme.primary),
                          label: Text(
                            'Select Your Video',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onPressed: _viewModel.pickAthleteVideo, // Call ViewModel
                        ),
                ),
              ),
              if (_viewModel.athleteVideoFile != null)
                TextButton(
                  onPressed: _viewModel.pickAthleteVideo, // Call ViewModel
                  child: const Text('Change Video'),
                ),
              const SizedBox(height: 20),

              // --- Mark as Done Button ---
              OutlinedButton.icon(
                // Read from ViewModel
                onPressed: _viewModel.isUploading ? null : _markAsDone,
                icon: _viewModel.isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_viewModel.isUploading
                    ? 'Submitting...'
                    : 'I Finished! Submit for Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[400],
                  side: BorderSide(color: Colors.green[400]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
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