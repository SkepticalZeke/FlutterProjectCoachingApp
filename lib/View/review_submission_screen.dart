import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  final Map<String, dynamic> routeArgs;
  const ReviewSubmissionScreen({super.key, required this.routeArgs});

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  // Video Players
  VideoPlayerController? _coachVideoController;
  VideoPlayerController? _athleteVideoController;

  // Data
  late Map<String, dynamic> _logData;
  late String _athleteId;
  late String _logId;

  bool _isInitializing = true;
  bool _isSubmitting = false;

  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // 1. Unpack the data
    _logData = widget.routeArgs['logData'] as Map<String, dynamic>;
    _athleteId = widget.routeArgs['athleteId'] as String;
    _logId = widget.routeArgs['logId'] as String;

    // 2. Initialize both video players
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    try {
      final String coachUrl = _logData['coachVideoUrl'] ?? '';
      final String athleteUrl = _logData['athleteVideoUrl'] ?? '';

      if (coachUrl.isEmpty || athleteUrl.isEmpty) {
        throw Exception('Video URLs not found.');
      }

      _coachVideoController =
          VideoPlayerController.networkUrl(Uri.parse(coachUrl));
      _athleteVideoController =
          VideoPlayerController.networkUrl(Uri.parse(athleteUrl));

      await _coachVideoController?.initialize();
      await _athleteVideoController?.initialize();

      setState(() {
        _isInitializing = false;
      });
      _coachVideoController?.play();
      _athleteVideoController?.play();
    } catch (e) {
      _showErrorSnackBar('Failed to load videos: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _coachVideoController?.dispose();
    _athleteVideoController?.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // Function to approve or reject the submission
  Future<void> _submitReview(bool isApproved) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final String newStatus = isApproved ? 'Approved' : 'Needs Work';
      final String feedback = _feedbackController.text.trim();
      final int bonusXp = isApproved ? 25 : 0; // Give 25 bonus XP for approval

      // Get references
      final logRef = _firestore
          .collection('athletes')
          .doc(_athleteId)
          .collection('logs')
          .doc(_logId);
      final athleteRef = _firestore.collection('athletes').doc(_athleteId);

      WriteBatch batch = _firestore.batch();

      // 1. Update the log
      batch.update(logRef, {
        'status': newStatus,
        'feedback': feedback,
      });

      // 2. If approved, grant bonus XP
      if (isApproved) {
        batch.update(athleteRef, {
          'totalXp': FieldValue.increment(bonusXp),
          'currentXp': FieldValue.increment(bonusXp),
          'stars': FieldValue.increment(10), // Give 10 stars as a reward
        });
      }

      // Commit changes
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Review submitted as "$newStatus" ${isApproved ? '+ $bonusXp Bonus XP!' : ''}'),
            backgroundColor: isApproved ? Colors.green : Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit review: $e');
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${(_logData['drill'] ?? 'Submission')}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isInitializing
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
                  _buildVideoPlayer(_coachVideoController, theme),
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
                  _buildVideoPlayer(_athleteVideoController, theme),
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
                    controller: _feedbackController,
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
                        onPressed: _isSubmitting ? null : () => _submitReview(false),
                      ),
                      // Approve Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _isSubmitting ? null : () => _submitReview(true),
                      ),
                    ],
                  ),
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoPlayer(
      VideoPlayerController? controller, ThemeData theme) {
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Error loading video.')),
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