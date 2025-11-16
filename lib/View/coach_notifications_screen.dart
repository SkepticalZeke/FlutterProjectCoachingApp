import 'package:flutter/material.dart';

// 1. Class name refactored
class CoachNotificationsScreen extends StatelessWidget {
  const CoachNotificationsScreen({super.key});

  // 2. Mock Data refactored: Athlete names and rewards
  final List<Map<String, dynamic>> notifications = const [
    // Streak & Milestones
    {
      'type': 'Milestone',
      // Changed 'Leo' to 'Leo Martinez' and 'kit' to 'badge'
      'title': 'Leo Martinez hit Level 5!',
      'message': 'He unlocked the "Lightning" profile badge!',
      'icon': Icons.stars,
      'color': Colors.amber
    },
    {
      'type': 'Streak',
      // Changed 'Mia' to 'Mia Williams'
      'title': 'Mia Williams is on Fire!',
      'message': 'Mia has maintained a 7-day training streak.',
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
    // Daily Reminders & Alerts
    {
      'type': 'Reminder',
      // Changed 'Max' to 'Max Donovan'
      'title': 'Reminder: Training Time',
      'message': 'Max Donovan hasn\'t started his drills today.',
      'icon': Icons.timer,
      'color': Colors.blue
    },
    {
      'type': 'Alert',
      // Changed 'Leo's' to 'Leo Martinez's'
      'title': 'Streak Alert!',
      'message':
          'Leo Martinez\'s 7-day streak is in danger. Encourage him to train!',
      'icon': Icons.warning,
      'color': Colors.red
    },
    // Weekly Summaries
    {
      'type': 'Summary',
      'title': 'Weekly Report Available',
      // Changed 'children\'s' to 'athletes\''
      'message': 'Review your athletes\' total XP and skill growth.',
      'icon': Icons.analytics,
      'color': Colors.green
    },
    {
      'type': 'Milestone',
      // Changed 'Max' to 'Max Donovan'
      'title': 'Max Donovan earned 500 total XP',
      'message': 'Great progress in the Cardio focus!',
      'icon': Icons.military_tech,
      'color': Colors.purple
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 3. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        // 4. UI Theme: Removed hardcoded colors, uses main.dart theme
      ),
      body: notifications.isEmpty
          // 5. UI Theme: Themed "Empty" message
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('No new alerts, all clear!',
                      style: TextStyle(
                          fontSize: 18,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  title: notification['title'] as String,
                  message: notification['message'] as String,
                  icon: notification['icon'] as IconData,
                  color: notification['color'] as Color,
                );
              },
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const NotificationTile({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 6. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Card(
      // 7. UI Theme: Card style comes from main.dart
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // 8. UI Theme: Semantic border color is good, keep it
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        // 9. UI Theme: Semantic icon color is good, keep it
        leading: Icon(
          icon,
          color: color,
          size: 30,
        ),
        title: Text(
          title,
          // 10. UI Theme: Text color will default to theme.onSurface (white)
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // 11. UI Theme: Subtitle text color will default to a lighter white
        subtitle: Text(message),
        // 12. UI Theme: Themed the trailing icon
        trailing: Icon(Icons.access_time,
            size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        onTap: () {
          // Future navigation
        },
      ),
    );
  }
}