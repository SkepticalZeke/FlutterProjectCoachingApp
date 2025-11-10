import 'package:flutter/material.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  // Mock Data for linked children
  final List<Map<String, dynamic>> linkedChildren = [
    {
      'name': 'Leo The Lion',
      'level': 4,
      'streak': 7,
      'progress': 1.0, // 1.0 = Completed all today's tasks
      'status': 'Completed All Drills',
      'skill_focus': 'Dribbling',
      'difficulty': 'Moderate',
    },
    {
      'name': 'Mia Goal-Getter',
      'level': 6,
      'streak': 2,
      'progress': 0.5, // 0.5 = Halfway through today's tasks
      'status': '1 Drill Remaining',
      'skill_focus': 'Shooting',
      'difficulty': 'Hard',
    },
    {
      'name': 'Max Striker',
      'level': 2,
      'streak': 0,
      'progress': 0.0,
      'status': 'Training Not Started',
      'skill_focus': 'Passing',
      'difficulty': 'Easy',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Notifications Button (NEW)
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed('/parent-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement Parent Logout logic here
              Navigator.of(context).pushNamedAndRemoveUntil('/parent-login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Guardian!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildOverviewCard(context),
            const SizedBox(height: 30),

            Text(
              'Linked Players Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),

            // List of linked children
            ...linkedChildren.map((child) => _buildChildTile(context, child)),
          ],
        ),
      ),
    );
  }

  // Helper widget for the main overview card
  Widget _buildOverviewCard(BuildContext context) {
    final completedCount = linkedChildren.where((c) => c['progress'] == 1.0).length;
    final totalCount = linkedChildren.length;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green[600]),
            title: const Text('Training Completion'),
            trailing: Text(
              '$completedCount / $totalCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.people, color: Theme.of(context).primaryColor),
            title: const Text('Total Linked Kids'),
            trailing: Text(
              '$totalCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for individual child's status tile
  Widget _buildChildTile(BuildContext context, Map<String, dynamic> child) {
    final bool isComplete = child['progress'] == 1.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isComplete ? Colors.green : Colors.grey[400],
          child: Icon(
            isComplete ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          child['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${child['status']}',
              style: TextStyle(color: isComplete ? Colors.green[700] : Colors.red[700]),
            ),
            Text('Current Streak: ${child['streak']} days'),
            Text('Level: ${child['level']}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // Navigate to Child Detail Page, passing the child's data
          Navigator.of(context).pushNamed(
            '/parent-child-detail',
            arguments: child,
          );
        },
      ),
    );
  }
}