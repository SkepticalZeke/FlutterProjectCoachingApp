import 'package:flutter/material.dart'; 

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  // Mock Data for all available drills in the app
  final List<Map<String, dynamic>> allDrills = const [
    {
      'name': 'Cone Dribbling Challenge',
      'goal': 'Complete 10 laps of a 5-cone course in under 90 seconds.',
      'time': 90,
      'category': 'Dribbling',
      'icon': Icons.directions_run,
      'color': Colors.green
    },
    {
      'name': 'Wall Pass Precision',
      'goal': 'Complete 30 accurate passes against a wall in 60 seconds.',
      'time': 60,
      'category': 'Passing',
      'icon': Icons.compare_arrows,
      'color': Colors.blue
    },
    {
      'name': 'Juggling Basics',
      'goal': 'Try to get 10 juggles in a row. Practice for 5 minutes.',
      'time': 300,
      'category': 'Control',
      'icon': Icons.sports_soccer,
      'color': Colors.orange
    },
    {
      'name': 'Shooting Accuracy',
      'goal': 'Hit 5 targets (cones) from 10 yards out.',
      'time': 180,
      'category': 'Shooting',
      'icon': Icons.adjust,
      'color': Colors.red
    },
    {
      'name': 'Stretching & Cool Down',
      'goal': 'Hold each stretch for 30 seconds.',
      'time': 120,
      'category': 'Fitness',
      'icon': Icons.self_improvement,
      'color': Colors.purple
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drills'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: allDrills.length,
        itemBuilder: (context, index) {
          final drill = allDrills[index];
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Icon(
                drill['icon'] as IconData,
                color: drill['color'] as Color,
                size: 40,
              ),
              title: Text(
                drill['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(drill['category'] as String),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Navigate to the detail screen, passing the drill data
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