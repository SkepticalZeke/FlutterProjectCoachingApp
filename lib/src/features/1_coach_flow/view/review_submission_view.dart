import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// Import the new ViewModel
import '../viewmodel/review_submission_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class ReviewSubmissionView extends StatefulWidget {
  final Map<String, dynamic> routeArgs;
  const ReviewSubmissionView({super.key, required this.routeArgs});

  @override
  State<ReviewSubmissionView> createState() => _ReviewSubmissionViewState();
}

class _ReviewSubmissionViewState extends State<ReviewSubmissionView> {
  // 1. The View owns its ViewModel
  final _viewModel = ReviewSubmissionViewModel();

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
    _viewModel.dispose();
    super.dispose();
  }

  // 5. Rebuild UI when ViewModel changes
  void _onViewModelChanged() {
    setState(() {});
  }

  // 6. "handle" function now calls the ViewModel
  Future<void> _submitReview(bool isApproved) async {
    bool success = await _viewModel.submitReview(isApproved);
    
    final int bonusXp = isApproved ? 25 : 0;
    final String status = isApproved ? 'Approved' : 'Needs Work';

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Review submitted as "$status" ${isApproved ? '+ $bonusXp Bonus XP!' : ''}'),
          backgroundColor: isApproved ? Colors.green : Colors.orange,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit review.'),
            backgroundColor: Colors.red),
      );
    }
  }

  // 7. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${_viewModel.drillName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _viewModel.isInitializing
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Coach Video ---
                  Text(
                    'Coach\'s Example',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 10),
                  _buildVideoPlayer(_viewModel.coachVideoController, theme),
                  const SizedBox(height: 30),

                  // --- Athlete Video ---
                  Text(
                    'Athlete\'s Submission',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 10),
                  _buildVideoPlayer(_viewModel.athleteVideoController, theme),
                  const SizedBox(height: 30),

                  // --- Feedback Section ---
                  Text(
                    'Feedback / Comments',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _viewModel.feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'e.g., "Great job! Keep your knees bent..."',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Needs Work'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _viewModel.isSubmitting
                            ? null
                            : () => _submitReview(false),
                      ),
                      // Approve Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _viewModel.isSubmitting
                            ? null
                            : () => _submitReview(true),
                      ),
                    ],
                  ),
                  if (_viewModel.isSubmitting)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }

  // --- Helper Widget (UI Only) ---
  Widget _buildVideoPlayer(
      VideoPlayerController? controller, ThemeData theme) {
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
            child: Text('Error loading video.',
                style: TextStyle(color: Colors.red))),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          IconButton(
            icon: Icon(controller.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            color: theme.colorScheme.primary,
            iconSize: 36,
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
          ),
        ],
      ),
    );
  }
}