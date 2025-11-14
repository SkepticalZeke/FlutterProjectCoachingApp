import 'package:flutter/material.dart';
import 'dart:async';

class DrillDetailScreen extends StatefulWidget {
  // This screen now accepts the drill data passed to it
  final Map<String, dynamic> drillData;

  const DrillDetailScreen({super.key, required this.drillData});

  @override
  State<DrillDetailScreen> createState() => _DrillDetailScreenState();
}

class _DrillDetailScreenState extends State<DrillDetailScreen> {
  // Drill data
  late String drillName;
  late String drillGoal;
  late int initialTimeSeconds;

  // Timer State Variables
  late int _currentTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Initialize state from the drill data passed to the widget
    drillName = widget.drillData['name'] ?? 'Drill';
    drillGoal = widget.drillData['goal'] ?? 'Complete the drill.';
    initialTimeSeconds = widget.drillData['time'] ?? 60; // Default 60 seconds

    _currentTime = initialTimeSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Timer logic (no changes needed) ---
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

  void _markAsDone() {
    _stopTimer();
    setState(() {
      _isCompleted = true;
    });
    // --- Firebase Placeholder ---
    ScaffoldMessenger.of(context).showSnackBar(
      // 1. Text refactored: General "XP"
      const SnackBar(
          content: Text('Drill Complete! 50 XP awarded!',
              style: TextStyle(fontWeight: FontWeight.bold))),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // --- 2. UI Theme: Updated Action Buttons ---
  Widget _buildActionButton() {
    if (_isCompleted) {
      return ElevatedButton.icon(
        onPressed: _resetTimer,
        icon: const Icon(Icons.refresh),
        label: const Text('Try Again'),
        style: ElevatedButton.styleFrom(
          // Use a neutral dark grey for "Try Again"
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
          // Amber is a good semantic color for "Pause", keep it
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
        // 3. UI Theme: REMOVED style, so it uses the main.dart theme (Cyan)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(drillName),
        // 5. UI Theme: Removed colors, uses main.dart theme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 6. UI Theme: Video Tutorial Area ---
            Container(
              height: 200,
              decoration: BoxDecoration(
                // Use theme surface color
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                // Use a subtle border
                border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.2)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ondemand_video,
                        size: 50,
                        // Use a light, secondary icon color
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text('Video Tutorial Placeholder',
                        // Use a light, secondary text color
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- Drill Instructions ---
            Text(
              'Goal:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // 7. UI Theme: Use primary cyan color
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 5),
            Text(
              drillGoal,
              // 8. UI Theme: Text will default to theme.onSurface (white)
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // --- 9. UI Theme: Timer/Counter Display ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Use theme surface color
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                // Removed shadow
              ),
              child: Column(
                children: [
                  Text(
                    'Time Remaining',
                    // Use light, secondary text color
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
                      // 10. UI Theme: This logic is perfect.
                      // It uses Red for urgency, and our (now Cyan) primaryColor
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
            if (!_isRunning && !_isCompleted)
              // 11. UI Theme: "Mark as Done" Button ---
              OutlinedButton.icon(
                onPressed: _markAsDone,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I Finished! Mark as Done'),
                style: OutlinedButton.styleFrom(
                  // Semantic color (green) is good, keep it
                  foregroundColor: Colors.green[400],
                  side: BorderSide(color: Colors.green[400]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}