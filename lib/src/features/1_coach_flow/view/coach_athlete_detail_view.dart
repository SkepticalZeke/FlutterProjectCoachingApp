import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/coach_athlete_detail_viewmodel.dart';

/*
  VIEW (V)
  Refactored CoachAthleteDetailView with:
  - Dashboard-style layout
  - Gradient backgrounds
  - Modern form inputs and dropdowns
  - enhanced activity log cards
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
          content: Text(success ? 'Routine settings saved!' : 'Failed to save settings.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
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
        ),
      );
      // Refresh logs to show the rest day entry if applicable
      _loadLogs();
    }
  }

  // Helper to parse dates from API (String or Timestamp Map)
  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '$athleteName\'s Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.95),
                colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.05) ?? Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadLogs(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context),
                  const SizedBox(height: 24),
                  _buildManagementCard(context),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    widget.athleteData['name'].substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.athleteData['name'],
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${widget.athleteData['level']} Athlete',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildStatItem(
                     context,
                     Icons.local_fire_department_rounded, 
                     '${widget.athleteData['streak']}', 
                     'Day Streak',
                     Colors.orange,
                   ),
                   Container(width: 1, height: 40, color: colorScheme.outlineVariant),
                   _buildStatItem(
                     context,
                     Icons.today_rounded, 
                     widget.athleteData['status'] as String, 
                     'Today',
                     (widget.athleteData['progress'] ?? 0.0) == 1.0 ? Colors.green : Colors.blue,
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Training Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Assign Drill Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Assign New Drill'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/assign-drill',
                      arguments: widget.athleteData);
                  _loadLogs();
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings Form
            _buildModernDropdown(
              'Difficulty Level',
              ['Easy', 'Moderate', 'Hard'],
              _viewModel.currentDifficulty,
              (val) => _viewModel.setDifficulty(val!),
              Icons.speed_rounded,
            ),
            const SizedBox(height: 16),
            _buildModernDropdown(
              'Skill Focus',
              ['General', 'Agility', 'Strength', 'Cardio'],
              _viewModel.currentSkillFocus,
              (val) => _viewModel.setSkillFocus(val!),
              Icons.fitness_center_rounded,
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Coach\'s Notes',
                alignLabelWithHint: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40), // Align icon to top
                  child: Icon(Icons.edit_note_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _addRestDay,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.error.withOpacity(0.2)),
                      ),
                    ),
                    child: const Text('Grant Rest Day'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _viewModel.isSaving ? null : _saveRoutineSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _viewModel.isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: colorScheme.onPrimary, strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown(String title, List<String> options,
      String currentValue, ValueChanged<String?> onChanged, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: title,
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        prefixIcon: Icon(icon, color: colorScheme.secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: colorScheme.surface,
      style: theme.textTheme.bodyLarge,
      items: options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down_rounded),
    );
  }

  // Changed from StreamBuilder to FutureBuilder
  Widget _buildActivityLogs(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: colorScheme.error)),
            ),
          );
        }
        
        final logs = snapshot.data ?? [];
        
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No activity logs yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final logData = logs[index];
            final String status = logData['status'] ?? 'Completed';
            
            IconData statusIcon;
            Color statusColor;
            Color bgColor;

            // Status Logic
            switch (status) {
              case 'Pending Review':
                statusIcon = Icons.hourglass_top_rounded;
                statusColor = Colors.orange.shade700;
                bgColor = Colors.orange.shade50;
                break;
              case 'Approved':
                statusIcon = Icons.check_circle_rounded;
                statusColor = Colors.green.shade700;
                bgColor = Colors.green.shade50;
                break;
              case 'Needs Work':
                statusIcon = Icons.warning_rounded;
                statusColor = Colors.red.shade700;
                bgColor = Colors.red.shade50;
                break;
              default:
                statusIcon = Icons.task_alt_rounded;
                statusColor = Colors.blue.shade700;
                bgColor = Colors.blue.shade50;
            }

            // Date Parsing safely
            final DateTime dateObj = _parseDate(logData['date']);
            final String date = "${dateObj.day}/${dateObj.month}";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: status == 'Pending Review' ? () async {
                    Map<String, dynamic> routeArgs = {
                      'athleteId': _athleteId,
                      'logId': logData['id'],
                      'logData': logData,
                    };
                    routeArgs.addAll(widget.athleteData);

                    await Navigator.of(context).pushNamed(
                      '/review-submission',
                      arguments: routeArgs,
                    );
                    _loadLogs();
                  } : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Date Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                date, 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: statusColor,
                                  fontSize: 12
                                )
                              ),
                              const SizedBox(height: 2),
                              Icon(statusIcon, color: statusColor, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Main Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                logData['drill'] ?? 'Unknown Drill',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${logData['xp']} XP',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Arrow (only if pending)
                        if (status == 'Pending Review')
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}