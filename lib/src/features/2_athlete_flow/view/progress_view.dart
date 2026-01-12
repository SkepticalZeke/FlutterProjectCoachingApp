import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/progress_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class ProgressView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const ProgressView({super.key, required this.athleteData});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView>
    with SingleTickerProviderStateMixin {
  // 1. The View owns its ViewModel
  final _viewModel = ProgressViewModel();

  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _logsFuture;
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Initialize ViewModel
    _viewModel.initialize(widget.athleteData);

    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    
    // Load Data
    _loadData();
  }

  void _loadData() {
    setState(() {
      _logsFuture = _viewModel.fetchAthleteLogs();
      _profileFuture = _viewModel.fetchAthleteProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper: Parse Date from API (String or Map) to DateTime
  DateTime? _parseDate(dynamic dateData) {
    if (dateData == null) return null;
    if (dateData is String) {
      return DateTime.tryParse(dateData);
    }
    // Handle Firestore Timestamp sent as Map {_seconds: ..., _nanoseconds: ...}
    if (dateData is Map && dateData.containsKey('_seconds')) {
      final int seconds = dateData['_seconds'];
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return null;
  }

  // Helper function to check if a day is completed
  bool _isDayCompleted(DateTime day, Set<DateTime> completedDays) {
    return completedDays.any((completedDay) => isSameDay(completedDay, day));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.show_chart), text: 'Skill Growth'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Wrap in RefreshIndicator for Pull-to-Refresh
          RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: _buildCalendarView(context),
          ),
          RefreshIndicator(
             onRefresh: () async => _loadData(),
             child: _buildSkillGrowthView(context),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Calendar View (FutureBuilder) ---
  Widget _buildCalendarView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // 3. Create the set of completed days
        Set<DateTime> completedDays = {};
        final logs = snapshot.data ?? [];
        
        for (var log in logs) {
          // Use helper to parse date safely
          final DateTime? date = _parseDate(log['date']);
          if (date != null) {
            completedDays.add(date);
          }
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      defaultTextStyle:
                          TextStyle(color: theme.colorScheme.onSurface),
                      weekendTextStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      outsideTextStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: theme.textTheme.titleLarge!,
                      leftChevronIcon: Icon(Icons.chevron_left,
                          color: theme.colorScheme.onSurface),
                      rightChevronIcon: Icon(Icons.chevron_right,
                          color: theme.colorScheme.onSurface),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        if (_isDayCompleted(day, completedDays)) {
                          return _buildCompletedDayMarker(theme, day);
                        }
                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        if (_isDayCompleted(day, completedDays)) {
                          return _buildCompletedDayMarker(theme, day);
                        }
                        // Default today look if not completed
                         return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                shape: BoxShape.circle
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Text('${day.day}'),
                            )
                          );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Green circles mark completed training days!',
                style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Extracted widget for cleaner code
  Widget _buildCompletedDayMarker(ThemeData theme, DateTime day) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Tab 2: Skill Growth (FutureBuilder) ---
  Widget _buildSkillGrowthView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Use latest data or fallback to widget arguments
          final athleteData = snapshot.data ?? widget.athleteData;
          final skillProgress =
              athleteData['skillProgress'] as Map<String, dynamic>? ?? {};

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                'XP Growth Over Time',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 10),
              Card(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart,
                            size: 50,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'XP Line Chart Placeholder',
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Current Skill Levels',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 15),
              
              if (skillProgress.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'No skill data available yet. Complete drills to see progress!'),
                )),
                
              ...skillProgress.entries.map((entry) {
                return SkillProgressIndicator(
                  skillName: entry.key,
                  progress: (entry.value ?? 0.0).toDouble(),
                );
              }),
            ],
          );
        });
  }
}

// --- SkillProgressIndicator widget ---
class SkillProgressIndicator extends StatelessWidget {
  final String skillName;
  final double progress;

  const SkillProgressIndicator({
    super.key,
    required this.skillName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color progressColor =
        Color.lerp(Colors.red, Colors.green, progress / 100)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${progress.toInt()}/100',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}