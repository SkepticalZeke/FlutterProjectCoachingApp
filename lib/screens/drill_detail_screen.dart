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
        _isRunning = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time\'s up! Try again or mark as done.')),
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
      const SnackBar(content: Text('Drill Complete! 50 XP awarded!', style: TextStyle(fontWeight: FontWeight.bold))),
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

  Widget _buildActionButton() {
    if (_isCompleted) {
      return ElevatedButton.icon(
        onPressed: _resetTimer,
        icon: const Icon(Icons.refresh),
        label: const Text('Try Again'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _currentTime == 0 ? _resetTimer : _startTimer,
        icon: Icon(_currentTime == 0 ? Icons.refresh : Icons.play_arrow),
        label: Text(_currentTime == 0 ? 'Restart Timer' : (_currentTime == initialTimeSeconds ? 'Start Training' : 'Resume')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drillName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Video Tutorial Area ---
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade300),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ondemand_video, size: 50, color: Colors.blueGrey),
                    SizedBox(height: 8),
                    Text('Video Tutorial Placeholder', style: TextStyle(color: Colors.blueGrey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- Drill Instructions ---
            Text(
              'Goal:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 5),
            Text(
              drillGoal,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // --- 2. Timer/Counter Display ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Time Remaining',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(_currentTime),
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: _currentTime < 10 && _currentTime > 0 ? Colors.red : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // --- 3. Action Buttons ---
            Center(child: _buildActionButton()),
            const SizedBox(height: 20),
            if (!_isRunning && !_isCompleted)
              OutlinedButton.icon(
                onPressed: _markAsDone,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I Finished! Mark as Done'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}