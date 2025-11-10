import 'package:flutter/material.dart';
import '../widgets/skill_progress_bar.dart';

class ChildDashboardScreen extends StatefulWidget {
  final String playerName;

  const ChildDashboardScreen({super.key, required this.playerName});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  // Mock Data for UI demonstration
  final double mockCurrentXp = 450;
  final double mockRequiredXp = 1000;
  final int mockLevel = 4;
  final int mockStreak = 7;

  // Mock list of today's activities - UPDATED with full drill data
  final List<Map<String, dynamic>> todayActivities = [
    {
      'name': 'Cone Dribbling Challenge',
      'goal': 'Complete 10 laps of a 5-cone course in under 90 seconds.',
      'time': 90,
      'icon': Icons.directions_run,
      'completed': false
    },
    {
      'name': 'Wall Pass Precision',
      'goal': 'Complete 30 accurate passes against a wall in 60 seconds.',
      'time': 60,
      'icon': Icons.sports_soccer,
      'completed': true
    },
    {
      'name': 'Stretching & Cool Down',
      'goal': 'Hold each stretch for 30 seconds.',
      'time': 120,
      'icon': Icons.self_improvement,
      'completed': false
    },
  ];

  // Helper function for Bottom Navigation
  void _onItemTapped(int index) {
    // Navigate away from the Home screen based on the index tapped
    switch (index) {
      case 0: // Drills
        Navigator.of(context).pushNamed('/training');
        break;
      case 1: // Avatar
        Navigator.of(context).pushNamed('/avatar');
        break;
      case 2: // Home (Do nothing if already on the Home/Dashboard screen)
        break;
      case 3: // Rewards
        Navigator.of(context).pushNamed('/rewards');
        break;
      case 4: // History/Progress
        Navigator.of(context).pushNamed('/progress');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoachFitness Training'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings'); // Navigate to Settings
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Daily Streak Counter (3) ---
            _buildStreakCard(context),
            const SizedBox(height: 20),

            // --- Avatar & Level Progress Bar (3, 5) ---
            _buildAvatarSection(context),
            const SizedBox(height: 20),

            // --- "Today's Activity" Preview (3, 4) ---
            _buildActivityList(context),
            const SizedBox(height: 30),

            // --- Rewards & Achievements Preview (6) ---
            _buildAchievementsPreview(context),
          ],
        ),
      ),

      // --- Bottom Navigation (5 items) ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Necessary for 5 items
        items: const <BottomNavigationBarItem>[
          // 0. Drills
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Drills'),
          // 1. Avatar
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Avatar'),
          // 2. Home (Center Item)
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // 3. Rewards
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Rewards'),
          // 4. History/Progress
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Progress'),
        ],
        // Set the current index to 2 (Home) since this is the Dashboard screen
        currentIndex: 2, 
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method for the Streak Card (No change)
  Widget _buildStreakCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.amber, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Training Streak:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
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

  // Helper method for the Avatar & Level Section (No change)
  Widget _buildAvatarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar Display
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/avatar'), // Navigate to Avatar screen on tap
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playerName, // Dynamic Nickname from input
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Motivational quote here!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // XP Bar from the custom widget
        SkillProgressBar(
          currentXp: mockCurrentXp,
          requiredXp: mockRequiredXp,
          level: mockLevel,
        ),
      ],
    );
  }

  // Helper method for Today's Activity List (UPDATED)
  Widget _buildActivityList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Training Plan",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
        ),
        const SizedBox(height: 10),
        
        ...todayActivities.map((activity) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                activity['icon'] as IconData,
                color: (activity['completed'] as bool) ? Colors.green : Theme.of(context).primaryColor,
              ),
              title: Text(
                activity['name'] as String,
                style: TextStyle(
                  decoration: (activity['completed'] as bool) ? TextDecoration.lineThrough : null,
                  color: (activity['completed'] as bool) ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: (activity['completed'] as bool)
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: () {
                        // Navigate directly to the drill detail screen
                        Navigator.of(context).pushNamed(
                          '/drill-detail',
                          arguments: activity,
                        );
                      },
                      child: const Text('Start'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  // Helper method for Rewards Preview (No change)
  Widget _buildAchievementsPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Achievements",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
        ),
        const SizedBox(height: 10),
        
        // Wrap badges in InkWell to navigate to RewardsScreen
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/rewards'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(Icons.star, '7-Day Champion!', Colors.amber),
              _buildBadge(Icons.speed, 'Dribbling Ace', Colors.blue),
              _buildBadge(Icons.verified, 'Pass Master', Colors.deepPurple),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for individual badge display (No change)
  Widget _buildBadge(IconData icon, String title, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}