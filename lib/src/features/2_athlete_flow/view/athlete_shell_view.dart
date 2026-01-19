import 'package:flutter/material.dart';
import 'athlete_dashboard_view.dart';
import 'training_view.dart';
import 'avatar_view.dart';
import 'rewards_view.dart';
import 'progress_view.dart';

/// A shell widget that provides persistent bottom navigation
/// across all athlete screens.
class AthleteShellView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  final int initialIndex;

  const AthleteShellView({
    super.key,
    required this.athleteData,
    this.initialIndex = 2, // Default to Home
  });

  @override
  State<AthleteShellView> createState() => _AthleteShellViewState();
}

class _AthleteShellViewState extends State<AthleteShellView> {
  late int _currentIndex;
  late Map<String, dynamic> _athleteData;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _athleteData = widget.athleteData;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Called by child views to update athlete data (e.g., after XP changes)
  void updateAthleteData(Map<String, dynamic> newData) {
    setState(() {
      _athleteData = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TrainingView(athleteData: _athleteData, embedded: true),
          AvatarView(athleteData: _athleteData, embedded: true),
          AthleteDashboardView(athleteData: _athleteData, embedded: true),
          RewardsView(athleteData: _athleteData, embedded: true),
          ProgressView(athleteData: _athleteData, embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center), label: 'Drills'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Avatar'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events), label: 'Rewards'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Progress'),
          ],
        ),
      ),
    );
  }
}
