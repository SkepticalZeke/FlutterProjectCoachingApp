import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  // 1. Mock Data: Synced with athlete_dashboard_screen
  final List<Map<String, dynamic>> achievements = const [
    // Streaks (Matches 7-day streak)
    {
      'name': '3-Day Streak',
      'unlocked': true,
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
    {
      'name': '7-Day Champion',
      'unlocked': true,
      'icon': Icons.local_fire_department,
      'color': Colors.red
    },
    {
      'name': '14-Day Legend',
      'unlocked': false,
      'icon': Icons.local_fire_department,
      'color': Colors.grey
    },

    // Effort & Milestones (1250 XP unlocks the 1k badge)
    {
      'name': 'First Drill',
      'unlocked': true,
      'icon': Icons.star_border,
      'color': Colors.yellow
    },
    {
      'name': '1,000 Total XP',
      'unlocked': true,
      'icon': Icons.military_tech,
      'color': Colors.blue
    },
    {
      'name': '5,000 Total XP',
      'unlocked': false,
      'icon': Icons.military_tech,
      'color': Colors.grey
    },

    // 2. Skill Badges: Updated to General Fitness
    {
      'name': 'Agility Ace', // From athlete dashboard
      'unlocked': true,
      'icon': Icons.speed,
      'color': Colors.blue
    },
    {
      'name': 'Cone Master', // From athlete dashboard
      'unlocked': true,
      'icon': Icons.timeline,
      'color': Colors.deepPurple
    },
    {
      'name': 'Strength Star', // New locked badge
      'unlocked': false,
      'icon': Icons.fitness_center,
      'color': Colors.grey
    },
    {
      'name': 'Cardio King', // New locked badge
      'unlocked': false,
      'icon': Icons.directions_run,
      'color': Colors.grey
    },
    {
      'name': 'Level 10',
      'unlocked': false,
      'icon': Icons.rocket_launch,
      'color': Colors.grey
    },
    {
      'name': 'First Gear', // Changed from 'Kit'
      'unlocked': false,
      'icon': Icons.checkroom,
      'color': Colors.grey
    },
  ];

  // 3. Mock stats: Synced with athlete_dashboard_screen
  final int currentLevel = 4;
  final int totalXp = 1250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trophy Cabinet'),
        // 4. UI Theme: Removed colors, uses main.dart theme
      ),
      body: Column(
        children: [
          // --- 1. Player Level & XP Summary ---
          _buildPlayerSummary(context),

          // --- 2. Achievements Grid ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 badges per row
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return AchievementBadge(
                  name: achievement['name'] as String,
                  icon: achievement['icon'] as IconData,
                  color: achievement['color'] as Color,
                  isUnlocked: achievement['unlocked'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the top summary card
  Widget _buildPlayerSummary(BuildContext context) {
    // 5. UI Theme: Get theme from context
    final theme = Theme.of(context);

    // 6. UI Theme: Replaced Container with Card
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Current Level: $currentLevel',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                // 7. UI Theme: Use primary cyan color
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total XP Earned: $totalXp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                // 8. UI Theme: Use light secondary text color
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A custom widget for displaying each badge
class AchievementBadge extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    // 9. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        // 10. UI Theme: Use theme surface color
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // 11. UI Theme: Use semantic color or dark grey
          color: isUnlocked ? color.withOpacity(0.7) : Colors.grey[800]!,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Opacity(
        // 12. UI Theme: Make locked badges a bit more visible
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 44,
              // 13. UI Theme: Semantic color is good, keep it
              color: isUnlocked ? color : Colors.grey[600],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                // 14. UI Theme: Use theme text color
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}