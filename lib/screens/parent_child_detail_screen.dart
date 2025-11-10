import 'package:flutter/material.dart';

class ParentChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ParentChildDetailScreen({super.key, required this.childData});

  @override
  State<ParentChildDetailScreen> createState() => _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState extends State<ParentChildDetailScreen> {
  // State variables for management tools
  late String _currentDifficulty;
  late String _currentSkillFocus;
  final TextEditingController _notesController = TextEditingController();

  // Mock data for Daily Activity Logs (Section 3)
  final List<Map<String, dynamic>> activityLogs = [
    {'date': 'Oct 23', 'drill': 'One-Foot Taps (150 reps)', 'status': 'Completed', 'xp': 50},
    {'date': 'Oct 23', 'drill': 'Wall Pass Precision (30 reps)', 'status': 'Completed', 'xp': 75},
    {'date': 'Oct 22', 'drill': 'Cone Dribbling Challenge (Timed)', 'status': 'Missed', 'xp': 0},
    {'date': 'Oct 21', 'drill': 'Basic Juggling (New Skill)', 'status': 'Completed', 'xp': 100},
  ];

  @override
  void initState() {
    super.initState();
    _currentDifficulty = widget.childData['difficulty'] ?? 'Easy';
    _currentSkillFocus = widget.childData['skill_focus'] ?? 'General';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveRoutineSettings() {
    // --- Firebase Placeholder ---
    // Here you would update the child's Firestore document with:
    // 1. _currentDifficulty
    // 2. _currentSkillFocus
    // 3. Optional: Save any notes from _notesController.text
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine settings saved successfully!')),
    );
  }

  void _addRestDay() {
    // --- Firebase Placeholder ---
    // Here you would set a flag in Firestore to mark the current day as a rest day
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.childData['name']} has been granted a rest day!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String childName = widget.childData['name'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('$childName\'s Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- General Stats Card (Section 3) ---
            _buildStatsCard(context),
            const SizedBox(height: 30),

            // --- Task/Activity Management (Section 4) ---
            _buildManagementCard(context),
            const SizedBox(height: 30),

            // --- Daily Activity Logs (Section 3 Detail) ---
            Text(
              'Recent Activity Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 10),
            _buildActivityLogs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
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
          Center(
            child: Text(
              '${widget.childData['name']} - Level ${widget.childData['level']}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
          const Divider(height: 25),
          _buildStatRow(Icons.local_fire_department, 'Current Streak', '${widget.childData['streak']} days', Colors.amber),
          _buildStatRow(Icons.military_tech, 'Total XP Earned', '1,250 XP', Colors.green),
          _buildStatRow(Icons.calendar_today, 'Today\'s Status', widget.childData['status'] as String, widget.childData['progress'] == 1.0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context) {
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
          Text(
            'Training Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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
          // Skill Focus Adjustment
          _buildDropdownTile(
            'Skill Focus',
            ['General', 'Dribbling', 'Passing', 'Shooting'],
            _currentSkillFocus,
            (newValue) {
              setState(() {
                _currentSkillFocus = newValue!;
              });
            },
          ),

          const SizedBox(height: 15),
          // Optional Notes/Comments
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
                child: Text('Add Rest Day', style: TextStyle(color: Colors.red[600])),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveRoutineSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: currentValue,
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
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
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
                    color: isCompleted ? Colors.amber[700] : Colors.grey,
                  ),
                ),
                Text(
                  log['status'] as String,
                  style: TextStyle(fontSize: 12, color: isCompleted ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}