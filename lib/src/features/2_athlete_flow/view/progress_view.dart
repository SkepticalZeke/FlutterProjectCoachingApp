import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    // 2. Initialize the ViewModel
    _viewModel.initialize(widget.athleteData);

    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    // We don't need to listen, as StreamBuilders will update the UI
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to check if a day is completed
  bool _isDayCompleted(DateTime day, Set<DateTime> completedDays) {
    return completedDays.any((completedDay) => isSameDay(completedDay, day));
  }

  // 3. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
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
          _buildCalendarView(context),
          _buildSkillGrowthView(context),
        ],
      ),
    );
  }

  // --- Tab 1: Calendar View (NOW A STREAMBUILDER) ---
  Widget _buildCalendarView(BuildContext context) {
    final theme = Theme.of(context);

    // 4. Listen to the stream from the ViewModel
    return StreamBuilder<QuerySnapshot>(
      stream: _viewModel.athleteLogsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // 5. Create the set of completed days from the log data
        Set<DateTime> completedDays = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('date')) {
              final timestamp = data['date'] as Timestamp;
              completedDays.add(timestamp.toDate());
            }
          }
        }

        // 6. Build the UI
        return SingleChildScrollView(
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
                    // 7. Use the live data to build the green circles
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        if (_isDayCompleted(day, completedDays)) {
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
                                    color: theme.colorScheme.onSurface),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        if (_isDayCompleted(day, completedDays)) {
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
                                    color: theme.colorScheme.onSurface),
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
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

  // --- Tab 2: Skill Growth (NOW A STREAMBUILDER) ---
  Widget _buildSkillGrowthView(BuildContext context) {
    final theme = Theme.of(context);

    // 8. Listen to the stream from the ViewModel
    return StreamBuilder<DocumentSnapshot>(
        stream: _viewModel.athleteStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Athlete data not found.'));
          }

          // 9. Get the skillProgress map from the document
          final athleteData = snapshot.data!.data() as Map<String, dynamic>;
          final skillProgress =
              athleteData['skillProgress'] as Map<String, dynamic>? ?? {};

          return ListView(
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
              // 10. Build the skill bars from the live map
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

// --- SkillProgressIndicator widget (Unchanged) ---
// (We should move this to lib/src/shared/widgets/ later)
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