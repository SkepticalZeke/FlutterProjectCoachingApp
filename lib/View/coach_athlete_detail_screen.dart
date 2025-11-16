import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORT ⭐️
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachAthleteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const CoachAthleteDetailScreen({super.key, required this.athleteData});

  @override
  State<CoachAthleteDetailScreen> createState() =>
      _CoachAthleteDetailScreenState();
}

class _CoachAthleteDetailScreenState extends State<CoachAthleteDetailScreen> {
  // ⭐️ GET FIRESTORE INSTANCE ⭐️
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  late String _currentDifficulty;
  late String _currentSkillFocus;
  final TextEditingController _notesController = TextEditingController();
  late String _athleteId; // To store the athlete's document ID

  bool _isSaving = false; // For loading indicator on save button

  // ⭐️ REMOVED MOCK ACTIVITY LOGS ⭐️

  @override
  void initState() {
    super.initState();
    // ⭐️ LOAD REAL DATA PASSED FROM DASHBOARD ⭐️
    _athleteId = widget.athleteData['id']; // Get the document ID
    _currentDifficulty = widget.athleteData['difficulty'] ?? 'Easy';
    _currentSkillFocus = widget.athleteData['skill_focus'] ?? 'General';
    _notesController.text =
        widget.athleteData['notes'] ?? ''; // Load saved notes
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ⭐️ UPDATED SAVE FUNCTION ⭐️
  void _saveRoutineSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Get a reference to the specific athlete's document
      DocumentReference athleteRef =
          _firestore.collection('athletes').doc(_athleteId);

      // 2. Update the document with the new values from the UI
      await athleteRef.update({
        'difficulty': _currentDifficulty,
        'skill_focus': _currentSkillFocus,
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Routine settings saved successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save settings: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  // ⭐️ UPDATED REST DAY FUNCTION ⭐️
  void _addRestDay() async {
    try {
      DocumentReference athleteRef =
          _firestore.collection('athletes').doc(_athleteId);

      // Update the athlete's status to show a rest day
      await athleteRef.update({
        'status': 'Rest Day (Completed)',
        'progress': 1.0, // Mark as "complete" for the day
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${widget.athleteData['name']} has been granted a rest day!'),
              backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add rest day: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String athleteName = widget.athleteData['name'] as String;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('$athleteName\'s Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- General Stats Card (Now uses 100% real data) ---
            _buildStatsCard(context),
            const SizedBox(height: 30),

            // --- Task/Activity Management (Wired to save) ---
            _buildManagementCard(context),
            const SizedBox(height: 30),

            // --- Daily Activity Logs (Now a real-time Stream) ---
            Text(
              'Recent Activity Logs',
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

  // ⭐️ STATS CARD NOW USES ONLY REAL DATA ⭐️
  Widget _buildStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${widget.athleteData['name']} - Level ${widget.athleteData['level']}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
            ),
            const Divider(height: 25),
            // All this data comes from the document passed to the screen
            _buildStatRow(
                Icons.local_fire_department,
                'Current Streak',
                '${widget.athleteData['streak']} days',
                Colors.amber),
            _buildStatRow(
                Icons.calendar_today,
                'Today\'s Status',
                widget.athleteData['status'] as String,
                widget.athleteData['progress'] == 1.0
                    ? Colors.green
                    : Colors.red),
            // ⭐️ Removed the mock "Total XP Earned" row
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context) {
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.primary),
            ),
            const Divider(),

            // ⭐️⭐️ NEW BUTTON ADDED ⭐️⭐️
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.assignment, color: theme.colorScheme.primary),
                label: Text(
                  'Assign a Custom Drill',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/assign-drill',
                      arguments: widget
                          .athleteData); // Pass athlete data to new screen
                },
              ),
            ),
            const SizedBox(height: 20),
            // ⭐️⭐️ END OF NEW BUTTON ⭐️⭐️

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
              ['General', 'Agility', 'Strength', 'Cardio'],
              _currentSkillFocus,
              (newValue) {
                setState(() {
                  _currentSkillFocus = newValue!;
                });
              },
            ),

            const SizedBox(height: 15),
            // Notes TextField (Now loads/saves)
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Coach\'s Notes',
                hintText: 'e.g., "Focus on form for squats..."',
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
                  child: Text('Add Rest Day',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  // ⭐️ Use _isSaving to disable button and show spinner
                  onPressed: _isSaving ? null : _saveRoutineSettings,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3),
                        )
                      : const Text('Save Settings'),
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
          DropdownButton<String>(
            value: currentValue,
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

  // ⭐️ ACTIVITY LOGS NOW A STREAMBUILDER ⭐️
  Widget _buildActivityLogs(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      // 1. Create a stream to this athlete's "logs" subcollection
      stream: _firestore
          .collection('athletes')
          .doc(_athleteId)
          .collection('logs')
          .orderBy('date',
              descending: true) // Show newest logs first
          .limit(10) // Only show the last 10
          .snapshots(),
      builder: (context, snapshot) {
        // 2. Handle Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 3. Handle Error
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // 4. Handle No Data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No activity logs found for this athlete.'),
            ),
          );
        }

        // 5. We have data! Build the list
        final logDocs = snapshot.data!.docs;

        return Column(
          children: logDocs.map((doc) {
            final logData = doc.data() as Map<String, dynamic>;
            final String status = logData['status'] ?? 'Completed';
            IconData statusIcon;
            Color statusColor;
            Widget? trailingWidget;

            // ⭐️ 6. SET UI BASED ON STATUS ⭐️
            switch (status) {
              case 'Pending Review':
                statusIcon = Icons.hourglass_top;
                statusColor = Colors.amber;
                trailingWidget = ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Review'),
                  onPressed: () {
                    // ⭐️ 7. NAVIGATE TO REVIEW SCREEN ⭐️
                    Navigator.of(context).pushNamed(
                      '/review-submission',
                      arguments: {
                        'athleteId': _athleteId,
                        'logId': doc.id, // Pass the log's ID
                        'logData': logData, // Pass all the log data
                      },
                    );
                  },
                );
                break;
              case 'Approved':
                statusIcon = Icons.check_circle;
                statusColor = Colors.green;
                break;
              case 'Needs Work':
                statusIcon = Icons.error;
                statusColor = Colors.red;
                break;
              default: // 'Completed' or 'Missed'
                statusIcon = status == 'Completed' ? Icons.task_alt : Icons.cancel;
                statusColor = status == 'Completed' ? Colors.green : Colors.red;
            }

            // Format the date (basic example)
            final Timestamp t = logData['date'] as Timestamp;
            final String date = t.toDate().toString().substring(0, 10);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  statusIcon,
                  color: statusColor,
                ),
                title: Text(logData['drill'] as String),
                subtitle: Text('Date: $date'),
                trailing: trailingWidget ?? // Show "Review" or XP
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${logData['xp']} XP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: status == 'Completed'
                                ? Colors.amber[700]
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
                      ],
                    ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}