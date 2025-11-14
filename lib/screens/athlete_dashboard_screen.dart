import 'package:flutter/material.dart';
// Note: You will need to make sure this widget is also refactored
// and themed for dark mode.
import '../widgets/skill_progress_bar.dart';

// 1. Class name refactored: ChildDashboardScreen -> AthleteDashboardScreen
class AthleteDashboardScreen extends StatefulWidget {
  // 2. Variable refactored: playerName -> athleteName
  final String athleteName;

  // 3. Constructor refactored
  const AthleteDashboardScreen({super.key, required this.athleteName});

  @override
  // 4. State class refactored
  State<AthleteDashboardScreen> createState() => _AthleteDashboardScreenState();
}

class _AthleteDashboardScreenState extends State<AthleteDashboardScreen> {
  // Mock Data (XP, Level, Streak)
  final double mockCurrentXp = 450;
  final double mockRequiredXp = 1000;
  final int mockLevel = 4;
  final int mockStreak = 7; // This matches Leo Martinez

  // 5. Mock Drills refactored: Synced to "Leo Martinez" (Agility Focus)
  final List<Map<String, dynamic>> todayActivities = [
    {
      'name': 'Agility Ladder: Ickey Shuffle',
      'goal': 'Complete 3 sets of the "Ickey Shuffle" drill.',
      'time': 90,
      'icon': Icons.directions_run,
      'completed': true // Let's say he finished one
    },
    {
      'name': 'Cone Weaving Drills',
      'goal': 'Weave through 10 cones and back, 5 times.',
      'time': 120,
      'icon': Icons.timeline, // Icon for weaving
      'completed': false
    },
    {
      'name': 'Plyometric Box Jumps',
      'goal': '3 sets of 10 box jumps.',
      'time': 120,
      'icon': Icons.arrow_upward, // Icon for jumping
      'completed': false
    },
  ];

  // Helper function for Bottom Navigation (no logic change needed)
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/training');
        break;
      case 1:
        Navigator.of(context).pushNamed('/avatar');
        break;
      case 2:
        break;
      case 3:
        Navigator.of(context).pushNamed('/rewards');
        break;
      case 4:
        Navigator.of(context).pushNamed('/progress');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 6. UI Theme: Get theme from context
    final ThemeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoachFitness Training'),
        // 7. UI Theme: Removed explicit colors to use main.dart theme
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Daily Streak Counter ---
            _buildStreakCard(context),
            const SizedBox(height: 20),

            // --- Avatar & Level Progress Bar ---
            _buildAvatarSection(context),
            const SizedBox(height: 20),

            // --- "Today's Activity" Preview ---
            _buildActivityList(context),
            const SizedBox(height: 30),

            // --- Rewards & Achievements Preview ---
            _buildAchievementsPreview(context),
          ],
        ),
      ),

      // --- Bottom Navigation ---
      bottomNavigationBar: BottomNavigationBar(
        // 8. UI Theme: BottomNav styling is now controlled by main.dart
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Drills'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Avatar'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Progress'),
        ],
        currentIndex: 2, // Home
        onTap: _onItemTapped,
        // 9. UI Theme: Removed hardcoded colors
      ),
    );
  }

  // Helper method for the Streak Card
  Widget _buildStreakCard(BuildContext context) {
    // 10. UI Theme: Changed from Green gradient to Cyan gradient
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary, // Cyan
            Colors.cyan.shade700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.amber, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Streak:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$mockStreak Days!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for the Avatar & Level Section
  Widget _buildAvatarSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar Display
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/avatar'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              // 11. UI Theme: Use theme surface color instead of Colors.white
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              // Shadow will be subtle on dark bg, which is fine
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CircleAvatar(
                    radius: 40,
                    // 12. UI Theme: Use primary color for avatar bg
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person,
                        size: 50,
                        // 13. UI Theme: Use black on cyan
                        color: theme.colorScheme.onPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // 14. Variable refactored: widget.playerName -> widget.athleteName
                      // We pass "Leo Martinez" when navigating here
                      widget.athleteName,
                      // 15. UI Theme: Use onSurface color
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Focus: Agility Drills', // ⭐️ Synced descriptive text
                      // 16. UI Theme: Use lighter text color
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  // 17. UI Theme: Use lighter icon color
                  child: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // XP Bar from the custom widget
        // Make sure 'SkillProgressBar' is also themed (e.g., uses theme.colorScheme.primary)
        SkillProgressBar(
          currentXp: mockCurrentXp,
          requiredXp: mockRequiredXp,
          level: mockLevel,
        ),
      ],
    );
  }

  // Helper method for Today's Activity List
  Widget _buildActivityList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Training Plan",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            // 18. UI Theme: Use primary cyan color
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        ...todayActivities.map((activity) {
          final bool isCompleted = activity['completed'] as bool;
          return Card(
            // Card style comes from main.dart theme
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                activity['icon'] as IconData,
                color: isCompleted
                    ? Colors.green // Keep green for "completed"
                    : theme.colorScheme.primary, // Cyan for "pending"
              ),
              title: Text(
                activity['name'] as String,
                style: TextStyle(
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  // 19. UI Theme: Use appropriate text color
                  color: isCompleted
                      ? theme.colorScheme.onSurface.withOpacity(0.5)
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/drill-detail',
                          arguments: activity,
                        );
                      },
                      // 20. UI Theme: Button is styled by main.dart
                      child: const Text('Start'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  // Helper method for Rewards Preview
  Widget _buildAchievementsPreview(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Achievements",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            // 21. UI Theme: Use primary cyan color
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/rewards'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 22. Badges refactored: Synced to Agility Focus
              _buildBadge(Icons.star, '7-Day Champion!', Colors.amber),
              _buildBadge(Icons.speed, 'Agility Ace', Colors.blue),
              _buildBadge(Icons.timeline, 'Cone Master', Colors.deepPurple),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for individual badge display
  Widget _buildBadge(IconData icon, String title, Color color) {
    // This widget's styling (light background) provides a nice contrast
    // to the dark theme, so we can keep it.
    // Just ensure the text is readable.
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // 23. UI Theme: Use a light color for contrast
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          // 24. UI Theme: Ensure text is readable
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}