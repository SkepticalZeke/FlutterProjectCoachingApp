import 'package:flutter/material.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  // Mock Notification Data (Section 5)
  final List<Map<String, dynamic>> notifications = const [
    // Streak & Milestones
    {'type': 'Milestone', 'title': 'Leo hit Level 5!', 'message': 'He unlocked the "Lightning Blue" kit!', 'icon': Icons.stars, 'color': Colors.amber},
    {'type': 'Streak', 'title': 'Mia is on Fire!', 'message': 'Mia has maintained a 7-day training streak.', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    // Daily Reminders & Alerts
    {'type': 'Reminder', 'title': 'Reminder: Training Time', 'message': 'Max hasn\'t started his drills today.', 'icon': Icons.timer, 'color': Colors.blue},
    {'type': 'Alert', 'title': 'Streak Alert!', 'message': 'Leo\'s 7-day streak is in danger. Encourage him to train!', 'icon': Icons.warning, 'color': Colors.red},
    // Weekly Summaries
    {'type': 'Summary', 'title': 'Weekly Report Available', 'message': 'Review your children\'s total XP and skill growth.', 'icon': Icons.analytics, 'color': Colors.green},
    {'type': 'Milestone', 'title': 'Max earned 500 total XP', 'message': 'Great progress in the Passing focus!', 'icon': Icons.military_tech, 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No new alerts, all clear!', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(message),
        trailing: const Icon(Icons.access_time, size: 14, color: Colors.grey),
        onTap: () {
          // Future navigation to a detailed report or child page
        },
      ),
    );
  }
}