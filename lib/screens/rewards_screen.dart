import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  // Mock Data for Rewards & Achievements (Section 6)
  final List<Map<String, dynamic>> achievements = const [
    // Streaks
    {'name': '3-Day Streak', 'unlocked': true, 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'name': '7-Day Champion', 'unlocked': true, 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'name': '14-Day Legend', 'unlocked': false, 'icon': Icons.local_fire_department, 'color': Colors.grey},
    
    // Effort & Milestones
    {'name': 'First Drill', 'unlocked': true, 'icon': Icons.star_border, 'color': Colors.yellow},
    {'name': '1,000 Total XP', 'unlocked': true, 'icon': Icons.military_tech, 'color': Colors.blue},
    {'name': '5,000 Total XP', 'unlocked': false, 'icon': Icons.military_tech, 'color': Colors.grey},
    
    // Skill Badges
    {'name': 'Dribbling Ace', 'unlocked': true, 'icon': Icons.directions_run, 'color': Colors.green},
    {'name': 'Passing Power', 'unlocked': false, 'icon': Icons.compare_arrows, 'color': Colors.grey},
    {'name': 'Shooting Star', 'unlocked': false, 'icon': Icons.adjust, 'color': Colors.grey},
    {'name': 'Level 10', 'unlocked': false, 'icon': Icons.rocket_launch, 'color': Colors.grey},
    {'name': 'First Kit', 'unlocked': false, 'icon': Icons.checkroom, 'color': Colors.grey},
    {'name': 'GoalBuddy Pro', 'unlocked': false, 'icon': Icons.shield, 'color': Colors.grey},
  ];

  // Mock player stats
  final int currentLevel = 4;
  final int totalXp = 1250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trophy Cabinet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Current Level: $currentLevel',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total XP Earned: $totalXp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withOpacity(0.7) : Colors.grey[300]!,
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
        opacity: isUnlocked ? 1.0 : 0.4,
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
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}