import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  // 1. Mock Data refactored: General fitness drills
  final List<Map<String, dynamic>> allDrills = const [
    {
      'name': 'Agility Ladder Drills',
      'goal': 'Complete 3 sets of the "Ickey Shuffle" drill.',
      'time': 90,
      'category': 'Agility', // Changed
      'icon': Icons.directions_run, // Good icon
      'color': Colors.blue // Agility
    },
    {
      'name': 'Bodyweight Strength',
      'goal': 'Complete 3 sets of 15 push-ups and 20 squats.',
      'time': 120,
      'category': 'Strength', // Changed
      'icon': Icons.fitness_center, // Good icon
      'color': Colors.red // Strength
    },
    {
      'name': 'High-Intensity Sprints',
      'goal': 'Perform 10 sprints of 30 seconds each.',
      'time': 300,
      'category': 'Cardio', // Changed
      'icon': Icons.timer, // Good icon
      'color': Colors.orange // Cardio
    },
    {
      'name': 'Plyometric Box Jumps',
      'goal': '3 sets of 10 box jumps.',
      'time': 180,
      'category': 'Strength', // Changed
      'icon': Icons.arrow_upward, // Good icon
      'color': Colors.red // Strength
    },
    {
      'name': 'Stretching & Cool Down',
      'goal': 'Hold each stretch for 30 seconds.',
      'time': 120,
      'category': 'Flexibility', // Changed
      'icon': Icons.self_improvement, // Good icon
      'color': Colors.purple // Flexibility
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 2. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drills'),
        // 3. UI Theme: Removed colors, uses main.dart theme
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: allDrills.length,
        itemBuilder: (context, index) {
          final drill = allDrills[index];

          return Card(
            // 4. UI Theme: Card style comes from main.dart
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Icon(
                drill['icon'] as IconData,
                // 5. UI Theme: Semantic color is good, keep it
                color: drill['color'] as Color,
                size: 40,
              ),
              title: Text(
                drill['name'] as String,
                // 6. UI Theme: Text uses theme color
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // 7. UI Theme: Subtitle uses lighter theme color
              subtitle: Text(drill['category'] as String),
              // 8. UI Theme: Chevron uses theme color
              trailing: Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
              onTap: () {
                // Navigation is correct
                Navigator.of(context).pushNamed(
                  '/drill-detail',
                  arguments: drill,
                );
              },
            ),
          );
        },
      ),
    );
  }
}