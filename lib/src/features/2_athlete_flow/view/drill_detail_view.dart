import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
// Import the new ViewModel
import '../viewmodel/drill_detail_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  Refactored DrillDetailView with:
  - "Active Mode" Gradient Background
  - Large, High-Contrast Timer
  - Modern Video Player Containers
  - Floating Action Controls
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
          content: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Text('Drill Submitted! +50 XP!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Submission failed. Please check video.')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 7. Build Action Button logic
  Widget _buildActionButton(ColorScheme colorScheme) {
    if (_viewModel.isCompleted) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _viewModel.resetTimer,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset & Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (_viewModel.isRunning) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _viewModel.stopTimer,
          icon: const Icon(Icons.pause_rounded),
          label: const Text('Pause Drill'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _viewModel.startTimer,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: Text(
            _viewModel.currentTime == (_viewModel.drillData['time'] as int? ?? 60)
                ? 'Start Training'
                : 'Resume',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 6,
            shadowColor: colorScheme.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
  }

  // 8. Main Build Method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _viewModel.drillName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.95),
                colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.05) ?? Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Coach's Video Player ---
                _buildCoachVideoSection(context),
                const SizedBox(height: 24),

                // --- Drill Instructions ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Goal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _viewModel.drillGoal.isEmpty ? "No description provided." : _viewModel.drillGoal,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Timer/Counter Display ---
                _buildTimerCard(context),
                const SizedBox(height: 32),

                // --- Action Buttons ---
                _buildActionButton(colorScheme),
                const SizedBox(height: 32),

                // --- Athlete's Submission Section ---
                if (!_viewModel.isCompleted) _buildSubmissionSection(context),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCoachVideoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Coach's Example",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          height: 220,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _viewModel.isCoachVideoInitialized
                    ? AspectRatio(
                        aspectRatio: _viewModel.coachVideoController!.value.aspectRatio,
                        child: VideoPlayer(_viewModel.coachVideoController!),
                      )
                    : _viewModel.coachVideoUrl.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off_outlined,
                                  size: 48, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text('No Example Video',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            ],
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                
                // Play/Pause Overlay
                if (_viewModel.isCoachVideoInitialized)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _viewModel.coachVideoController!.value.isPlaying
                              ? _viewModel.coachVideoController!.pause()
                              : _viewModel.coachVideoController!.play();
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: Center(
                          child: Icon(
                            _viewModel.coachVideoController!.value.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 64,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isLowTime = _viewModel.currentTime < 10 && _viewModel.currentTime > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'TIME REMAINING',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(_viewModel.currentTime),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace', // Use monospace for stable numbers
              height: 1.0,
              color: isLowTime ? colorScheme.error : colorScheme.primary,
              shadows: isLowTime ? [
                BoxShadow(color: colorScheme.error.withOpacity(0.4), blurRadius: 20)
              ] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_rounded, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Submission',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Record yourself performing the drill',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Video Picker / Preview
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
            // Dotted border effect can be simulated with CustomPaint, but keeping it simple for now
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_viewModel.athleteVideoController != null &&
                    _viewModel.athleteVideoController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _viewModel.athleteVideoController!.value.aspectRatio,
                    child: VideoPlayer(_viewModel.athleteVideoController!),
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _viewModel.pickAthleteVideo,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_call_rounded,
                                size: 48, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to Record / Upload',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Change button overlay if video exists
                  if (_viewModel.athleteVideoFile != null)
                     Positioned(
                       bottom: 8,
                       right: 8,
                       child: IconButton.filledTonal(
                         onPressed: _viewModel.pickAthleteVideo, 
                         icon: const Icon(Icons.edit),
                         tooltip: "Change Video",
                       ),
                     ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: FilledButton.icon(
            onPressed: _viewModel.isUploading ? null : _markAsDone,
            icon: _viewModel.isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded),
            label: Text(_viewModel.isUploading ? 'Uploading...' : 'Submit Drill'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}