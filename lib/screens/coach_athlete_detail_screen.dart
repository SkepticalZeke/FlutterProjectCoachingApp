import 'package:flutter/material.dart';

// 1. Class name refactored
class CoachAthleteDetailScreen extends StatefulWidget {
  // 2. Variable refactored: childData -> athleteData
  final Map<String, dynamic> athleteData;

  // 3. Constructor refactored
  const CoachAthleteDetailScreen({super.key, required this.athleteData});

  @override
  // 4. State class refactored
  State<CoachAthleteDetailScreen> createState() =>
      _CoachAthleteDetailScreenState();
}

class _CoachAthleteDetailScreenState extends State<CoachAthleteDetailScreen> {
  // State variables
  late String _currentDifficulty;
  late String _currentSkillFocus;
  final TextEditingController _notesController = TextEditingController();

  // 5. Mock Data refactored: General fitness terms
  final List<Map<String, dynamic>> activityLogs = [
    {
      'date': 'Nov 11',
      'drill': 'Burpees (30 reps)',
      'status': 'Completed',
      'xp': 75
    },
    {
      'date': 'Nov 11',
      'drill': 'Agility Ladder (Timed)',
      'status': 'Completed',
      'xp': 50
    },
    {
      'date': 'Nov 10',
      'drill': 'Push-ups (3 sets)',
      'status': 'Missed',
      'xp': 0
    },
    {
      'date': 'Nov 09',
      'drill': 'Plank (New Skill)',
      'status': 'Completed',
      'xp': 100
    },
  ];

  @override
  void initState() {
    super.initState();
    // 6. Init state refactored: Use athleteData
    _currentDifficulty = widget.athleteData['difficulty'] ?? 'Easy';
    _currentSkillFocus = widget.athleteData['skill_focus'] ?? 'General';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveRoutineSettings() {
    // --- Firebase Placeholder ---
    // 7. Text refactored: update athlete's document
    // Here you would update the athlete's Firestore document with:
    // 1. _currentDifficulty
    // 2. _currentSkillFocus
    // 3. Optional: Save any notes from _notesController.text

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine settings saved successfully!')),
    );
  }

  void _addRestDay() {
    // --- Firebase Placeholder ---
    ScaffoldMessenger.of(context).showSnackBar(
      // 8. Text refactored: Use athleteData['name']
      SnackBar(
          content:
              Text('${widget.athleteData['name']} has been granted a rest day!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 9. Variable refactored: childName -> athleteName
    final String athleteName = widget.athleteData['name'] as String;
    // 10. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // 11. Text refactored
        title: Text('$athleteName\'s Details'),
        // 12. UI Theme: Removed colors, uses main.dart theme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- General Stats Card ---
            _buildStatsCard(context),
            const SizedBox(height: 30),

            // --- Task/Activity Management ---
            _buildManagementCard(context),
            const SizedBox(height: 30),

            // --- Daily Activity Logs ---
            Text(
              'Recent Activity Logs',
              // 13. UI Theme: Use theme text style
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActivityLogs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    // 14. UI Theme: Replaced Container with Card
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                // 15. Text refactored: Use athleteData
                '${widget.athleteData['name']} - Level ${widget.athleteData['level']}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // 16. UI Theme: Use primary cyan color
                    color: theme.colorScheme.primary),
              ),
            ),
            const Divider(height: 25),
            // 17. Data refactored: Use athleteData
            _buildStatRow(
                Icons.local_fire_department,
                'Current Streak',
                '${widget.athleteData['streak']} days',
                Colors.amber),
            _buildStatRow(Icons.military_tech, 'Total XP Earned', '1,250 XP',
                Colors.green),
            _buildStatRow(
                Icons.calendar_today,
                'Today\'s Status',
                widget.athleteData['status'] as String,
                widget.athleteData['progress'] == 1.0
                    ? Colors.green
                    : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Semantic color (amber, green, red) is good, keep it
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          // 18. UI Theme: Use light secondary text
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const Spacer(),
          // 19. UI Theme: Use primary text
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context) {
    final theme = Theme.of(context);
    // 20. UI Theme: Replaced Container with Card
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Management',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // 21. UI Theme: Use primary cyan color
                  color: theme.colorScheme.primary),
            ),
            const Divider(),

            // Difficulty Adjustment
            _buildDropdownTile(
              'Difficulty',
              ['Easy', 'Moderate', 'Hard'],
              _currentDifficulty,
              (newValue) {
                setState(() {
                  _currentDifficulty = newValue!;
                });
              },
            ),
            // 22. ⭐️⭐️ FIX: Data refactored: General fitness terms
            _buildDropdownTile(
              'Skill Focus',
              // This list now matches the data from the dashboard
              ['General', 'Agility', 'Strength', 'Cardio'],
              _currentSkillFocus,
              (newValue) {
                setState(() {
                  _currentSkillFocus = newValue!;
                });
              },
            ),

            const SizedBox(height: 15),
            // 23. UI Theme: Themed TextField
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Optional Notes/Comments',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _addRestDay,
                  // 24. UI Theme: Use theme error color for "rest day"
                  child: Text('Add Rest Day',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveRoutineSettings,
                  // 25. UI Theme: Button style comes from main.dart
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, List<String> options,
      String currentValue, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title:',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          // 26. UI Theme: Themed DropdownButton
          DropdownButton<String>(
            value: currentValue,
            // 27. UI Theme: Set dropdown background color
            dropdownColor: theme.colorScheme.surface,
            style: theme.textTheme.bodyLarge,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogs(BuildContext context) {
    return Column(
      children: activityLogs.map((log) {
        final bool isCompleted = log['status'] == 'Completed';
        return Card(
          // 28. UI Theme: Card style comes from main.dart
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            // Semantic colors are good, keep them
            leading: Icon(
              isCompleted ? Icons.task_alt : Icons.cancel,
              color: isCompleted ? Colors.green : Colors.red,
            ),
            title: Text(log['drill'] as String),
            subtitle: Text('Date: ${log['date']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${log['xp']} XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // Semantic color (amber) is good, keep it
                    color: isCompleted ? Colors.amber[700] : Colors.grey,
                  ),
                ),
                Text(
                  log['status'] as String,
                  // Semantic colors (green/red) are good, keep them
                  style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}