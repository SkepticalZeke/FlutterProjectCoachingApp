import 'package:flutter/material.dart';

// 1. Class name refactored: ParentDashboardScreen -> CoachDashboardScreen
class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  // 2. State class refactored
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  // 3. Mock Data refactored: linkedChildren -> linkedAthletes
  // ⭐️ UPDATED: Skill focus now uses single words to match dropdown
  final List<Map<String, dynamic>> linkedAthletes = [
    {
      'name': 'Leo Martinez',
      'level': 4,
      'streak': 7,
      'progress': 1.0,
      'status': 'Completed All Drills',
      'skill_focus': 'Agility', // Changed from 'Agility Drills'
      'difficulty': 'Moderate',
    },
    {
      'name': 'Mia Williams',
      'level': 6,
      'streak': 2,
      'progress': 0.5,
      'status': '1 Drill Remaining',
      'skill_focus': 'Strength', // Changed from 'Strength Training'
      'difficulty': 'Hard',
    },
    {
      'name': 'Max Donovan',
      'level': 2,
      'streak': 0,
      'progress': 0.0,
      'status': 'Training Not Started',
      'skill_focus': 'Cardio', // Changed from 'Cardio Endurance'
      'difficulty': 'Easy',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 4. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // 5. Text refactored: 'Parent Dashboard' -> 'Coach Dashboard'
        title: const Text('Coach Dashboard'),
        // AppBar style is now controlled by main.dart
        actions: [
          // Notifications Button
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // This route '/coach-notifications' is correct
              Navigator.of(context).pushNamed('/coach-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 6. Navigation refactored: '/coach-login' is correct
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/coach-login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 7. Text refactored: 'Guardian' -> 'Coach'
            Text(
              'Welcome, Coach!',
              // FIX: Use titleLarge for a safer, non-overflowing size
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24, // Explicitly setting size
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // 9. UI Theme: Use themed overview card
            _buildOverviewCard(context),
            const SizedBox(height: 30),

            // 10. Text refactored: 'Linked Players' -> 'Athletes'
            Text(
              'Athletes Overview',
              // FIX: Use titleLarge for a safer, non-overflowing size
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // 12. List refactored: Use 'linkedAthletes' and '_buildAthleteTile'
            ...linkedAthletes
                .map((athlete) => _buildAthleteTile(context, athlete)),
          ],
        ),
      ),
    );
  }

  // Helper widget for the main overview card
  Widget _buildOverviewCard(BuildContext context) {
    // 13. Data refactored: Use 'linkedAthletes'
    final completedCount =
        linkedAthletes.where((c) => c['progress'] == 1.0).length;
    final totalCount = linkedAthletes.length;
    final theme = Theme.of(context);

    // 14. UI Theme: Replaced Container with Card to use theme
    return Card(
      // Card color, shadow, and shape are now from main.dart
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Summary',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green[600]),
              title: const Text('Training Completion'),
              trailing: Text(
                '$completedCount / $totalCount',
                // FIX: Use titleMedium for a safer, non-overflowing size
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              // 15. UI Theme: Use cyan for "people" icon
              leading: Icon(Icons.people, color: theme.colorScheme.primary),
              // 16. Text refactored: 'Kids' -> 'Athletes'
              title: const Text('Total Linked Athletes'),
              trailing: Text(
                '$totalCount',
                // FIX: Use titleMedium for a safer, non-overflowing size
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 17. Helper widget refactored: _buildChildTile -> _buildAthleteTile
  Widget _buildAthleteTile(
      BuildContext context, Map<String, dynamic> athlete) {
    // 18. Data refactored: 'child' -> 'athlete'
    final bool isComplete = athlete['progress'] == 1.0;

    return Card(
      // Card style is from main.dart
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          // Semantic colors (green/grey) are good, keeping them
          backgroundColor: isComplete ? Colors.green : Colors.grey[700],
          child: Icon(
            isComplete ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          // 19. Data refactored: 'child' -> 'athlete'
          athlete['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              // 20. Data refactored: 'child' -> 'athlete'
              'Status: ${athlete['status']}',
              // Semantic colors (green/red) are good, keeping them
              style: TextStyle(
                  color: isComplete ? Colors.green[400] : Colors.red[400]),
            ),
            // 21. Data refactored: 'child' -> 'athlete'
            Text('Current Streak: ${athlete['streak']} days'),
            Text('Level: ${athlete['level']}'),
          ],
        ),
        // 22. UI Theme: Use theme color for chevron
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        onTap: () {
          // 23. Navigation refactored: Navigate to coach-athlete-detail
          Navigator.of(context).pushNamed(
            '/coach-athlete-detail',
            // 24. Data refactored: pass 'athlete' data
            arguments: athlete,
          );
        },
      ),
    );
  }
}