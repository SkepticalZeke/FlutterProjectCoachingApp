import 'package:flutter/material.dart';

// ⭐️ 1. CONSTRUCTOR UPDATED ⭐️
// Now accepts the athleteData map passed from the nav bar
class RewardsScreen extends StatelessWidget {
  final Map<String, dynamic> athleteData;
  const RewardsScreen({super.key, required this.athleteData});

  // Mock Data for Rewards & Achievements (Section 6)
  // (We can connect this to Firebase later)
  final List<Map<String, dynamic>> achievements = const [
    // Streaks
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

    // Effort & Milestones
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

    // Skill Badges: Updated to General Fitness
    {
      'name': 'Agility Ace',
      'unlocked': true,
      'icon': Icons.speed,
      'color': Colors.blue
    },
    {
      'name': 'Cone Master',
      'unlocked': true,
      'icon': Icons.timeline,
      'color': Colors.deepPurple
    },
    {
      'name': 'Strength Star',
      'unlocked': false,
      'icon': Icons.fitness_center,
      'color': Colors.grey
    },
    {
      'name': 'Cardio King',
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
      'name': 'First Gear',
      'unlocked': false,
      'icon': Icons.checkroom,
      'color': Colors.grey
    },
  ];

  // ⭐️ 2. REMOVED MOCK STATS (currentLevel, totalXp) ⭐️

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trophy Cabinet'),
      ),
      body: Column(
        children: [
          // ⭐️ 3. PASS REAL ATHLETE DATA TO THE SUMMARY WIDGET ⭐️
          _buildPlayerSummary(context, athleteData),

          // --- 2. Achievements Grid (Unchanged) ---
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

  // ⭐️ 4. HELPER WIDGET UPDATED ⭐️
  // Now accepts the athleteData map
  Widget _buildPlayerSummary(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);

    // ⭐️ 5. GET LIVE DATA FROM THE MAP ⭐️
    final int currentLevel = athleteData['level'] ?? 1;
    final int totalXp = (athleteData['totalXp'] ?? 0)
        .toInt(); // Use totalXp from drill update

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Current Level: $currentLevel', // ⭐️ Use real data
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total XP Earned: $totalXp', // ⭐️ Use real data
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AchievementBadge widget (Unchanged) ---
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
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
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 44,
              color: isUnlocked ? color : Colors.grey[600],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}