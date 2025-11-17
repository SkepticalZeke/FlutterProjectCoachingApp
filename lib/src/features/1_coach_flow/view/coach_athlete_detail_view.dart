import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new ViewModel
import '../viewmodel/coach_athlete_detail_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class CoachAthleteDetailView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const CoachAthleteDetailView({super.key, required this.athleteData});

  @override
  State<CoachAthleteDetailView> createState() =>
      _CoachAthleteDetailViewState();
}

class _CoachAthleteDetailViewState extends State<CoachAthleteDetailView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachAthleteDetailViewModel();

  final TextEditingController _notesController = TextEditingController();
  late String _athleteId; // We get this from the widget data

  @override
  void initState() {
    super.initState();
    // 2. Initialize the ViewModel
    _athleteId = widget.athleteData['id'];
    _viewModel.initialize(widget.athleteData);
    _notesController.text = widget.athleteData['notes'] ?? '';

    // 3. Listen for changes
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    // 4. Clean up
    _viewModel.removeListener(_onViewModelChanged);
    _notesController.dispose();
    super.dispose();
  }

  // 5. Rebuild UI when ViewModel changes
  void _onViewModelChanged() {
    setState(() {});
  }

  // 6. "handle" functions now call the ViewModel
  void _saveRoutineSettings() async {
    bool success = await _viewModel.saveRoutineSettings(
      athleteId: _athleteId,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Routine settings saved!'
              : 'Failed to save settings.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _addRestDay() async {
    bool success = await _viewModel.addRestDay(_athleteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${widget.athleteData['name']} has been granted a rest day!'
              : 'Failed to add rest day.'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  // 7. Build method is "dumb"
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
            _buildStatsCard(context),
            const SizedBox(height: 30),
            _buildManagementCard(context),
            const SizedBox(height: 30),
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

  // --- Helper Widgets ---
  // These are part of the View, as they are UI-only

  // Stats card reads from the *initial* data (doesn't need live updates)
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
            _buildStatRow(
                Icons.local_fire_department,
                'Current Streak',
                '${widget.athleteData['streak']} days',
                Colors.amber),
            _buildStatRow(
                Icons.calendar_today,
                'Today\'s Status',
                widget.athleteData['status'] as String,
                (widget.athleteData['progress'] ?? 0.0) == 1.0
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

  // Management card reads and writes to the ViewModel
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
                      arguments: widget.athleteData);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdownTile(
              'Difficulty',
              ['Easy', 'Moderate', 'Hard'],
              _viewModel.currentDifficulty, // Read from ViewModel
              (newValue) {
                _viewModel.setDifficulty(newValue!); // Write to ViewModel
              },
            ),
            _buildDropdownTile(
              'Skill Focus',
              ['General', 'Agility', 'Strength', 'Cardio'],
              _viewModel.currentSkillFocus, // Read from ViewModel
              (newValue) {
                _viewModel.setSkillFocus(newValue!); // Write to ViewModel
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _notesController, // Managed by View
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Coach\'s Notes',
                hintText: 'e.g., "Focus on form for squats..."',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _addRestDay, // Call handler
                  child: Text('Add Rest Day',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      _viewModel.isSaving ? null : _saveRoutineSettings, // Read state
                  child: _viewModel.isSaving
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

  // Activity logs now get their stream from the ViewModel
  Widget _buildActivityLogs(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _viewModel.getAthleteLogs(_athleteId), // Call ViewModel
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No activity logs found for this athlete.'),
            ),
          );
        }

        final logDocs = snapshot.data!.docs;

        return Column(
          children: logDocs.map((doc) {
            final logData = doc.data() as Map<String, dynamic>;
            final String status = logData['status'] ?? 'Completed';
            IconData statusIcon;
            Color statusColor;
            Widget? trailingWidget;

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
                    // Pass all data to the review screen
                    Map<String, dynamic> routeArgs = {
                      'athleteId': _athleteId,
                      'logId': doc.id,
                      'logData': logData,
                    };
                    // Pass the *original* athlete data as well for nav
                    routeArgs.addAll(widget.athleteData);
                    
                    Navigator.of(context).pushNamed(
                      '/review-submission',
                      arguments: routeArgs,
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
              default:
                statusIcon =
                    status == 'Completed' ? Icons.task_alt : Icons.cancel;
                statusColor =
                    status == 'Completed' ? Colors.green : Colors.red;
            }

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
                trailing: trailingWidget ??
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