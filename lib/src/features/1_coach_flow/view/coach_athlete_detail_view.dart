import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
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
  State<CoachAthleteDetailView> createState() => _CoachAthleteDetailViewState();
}

class _CoachAthleteDetailViewState extends State<CoachAthleteDetailView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachAthleteDetailViewModel();

  final TextEditingController _notesController = TextEditingController();
  late String _athleteId;

  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _athleteId = widget.athleteData['id'];
    _viewModel.initialize(widget.athleteData);
    _notesController.text = widget.athleteData['notes'] ?? '';

    // Listen for changes
    _viewModel.addListener(_onViewModelChanged);

    // Load initial logs
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logsFuture = _viewModel.fetchAthleteLogs(_athleteId);
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  // --- ACTIONS ---

  void _saveRoutineSettings() async {
    bool success = await _viewModel.saveRoutineSettings(
      athleteId: _athleteId,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Routine settings saved!' : 'Failed to save settings.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Refresh logs to show the rest day entry if applicable
      _loadLogs();
    }
  }

  // Helper to parse dates from API (String or Timestamp Map)
  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    // Handle Firestore Timestamp sent as Map {_seconds: ..., _nanoseconds: ...}
    if (dateData is Map && dateData.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(dateData['_seconds'] * 1000);
    }
    return DateTime.now();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    final String athleteName = widget.athleteData['name'] as String;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '$athleteName\'s Details',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Dark Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadLogs(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context),
                  const SizedBox(height: 24),
                  _buildManagementCard(context),
                  const SizedBox(height: 32),
                  
                  // Logs Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Small refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh,
                              size: 18, color: Color(0xFF00BCD4)),
                          onPressed: _loadLogs,
                          tooltip: "Refresh Logs",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActivityLogs(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.person, size: 30, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.athleteData['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Level ${widget.athleteData['level']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF00BCD4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.local_fire_department,
                  'Streak',
                  '${widget.athleteData['streak']} days',
                  Colors.orange,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _buildStatItem(
                  Icons.calendar_today,
                  'Status',
                  widget.athleteData['status'] as String,
                  (widget.athleteData['progress'] ?? 0.0) == 1.0
                      ? Colors.green
                      : Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildManagementCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          
          // Assign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.assignment_add, size: 20),
              label: const Text('Assign Custom Drill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: theme.primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await Navigator.of(context).pushNamed('/assign-drill',
                    arguments: widget.athleteData);
                _loadLogs();
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Dropdowns
          _buildDropdownTile(
            'Difficulty',
            ['Easy', 'Moderate', 'Hard'],
            _viewModel.currentDifficulty,
            (newValue) {
              _viewModel.setDifficulty(newValue!);
            },
          ),
          const Divider(height: 24),
          _buildDropdownTile(
            'Skill Focus',
            ['General', 'Agility', 'Strength', 'Cardio'],
            _viewModel.currentSkillFocus,
            (newValue) {
              _viewModel.setSkillFocus(newValue!);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Notes Field
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Coach\'s Notes',
              hintText: 'e.g., "Focus on form for squats..."',
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _addRestDay,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Add Rest Day'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    _viewModel.isSaving ? null : _saveRoutineSettings,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: theme.primaryColor),
                ),
                child: _viewModel.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, List<String> options,
      String currentValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              items: options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Changed from StreamBuilder to FutureBuilder
  Widget _buildActivityLogs(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  'No activity logs yet',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Column(
          children: logs.map((logData) {
            final String status = logData['status'] ?? 'Completed';
            IconData statusIcon;
            Color statusColor;
            Widget? trailingWidget;

            // Status Logic
            switch (status) {
              case 'Pending Review':
                statusIcon = Icons.hourglass_top;
                statusColor = Colors.amber;
                trailingWidget = SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Review'),
                    onPressed: () async {
                      Map<String, dynamic> routeArgs = {
                        'athleteId': _athleteId,
                        'logId': logData['id'], // Ensure ID is present
                        'logData': logData,
                      };
                      routeArgs.addAll(widget.athleteData);

                      await Navigator.of(context).pushNamed(
                        '/review-submission',
                        arguments: routeArgs,
                      );
                      // Refresh upon return
                      _loadLogs();
                    },
                  ),
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

            // Date Parsing safely
            final DateTime dateObj = _parseDate(logData['date']);
            final String date = dateObj.toIso8601String().substring(0, 10);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            logData['drill'] ?? 'Unknown Drill',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: $date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailingWidget != null)
                      trailingWidget
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${logData['xp']} XP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: status == 'Completed'
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
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