import 'package:flutter/material.dart';
// Used for mock skill data
import 'package:table_calendar/table_calendar.dart'; // NEW IMPORT

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for completed training days (now used!)
  final List<DateTime> completedDays = [
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 2)),
    DateTime.now().subtract(const Duration(days: 3)),
    DateTime.now().subtract(const Duration(days: 5)),
    DateTime.now().subtract(const Duration(days: 7)),
  ];

  // 1. Mock Data refactored: General fitness terms
  final Map<String, double> skillProgress = {
    'Agility': 75.0, // Was Dribbling
    'Strength': 50.0, // Was Passing
    'Cardio': 30.0, // Was Shooting
    'Stamina': 60.0,
  };

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to check if a day is completed
  bool _isDayCompleted(DateTime day) {
    return completedDays.any((completedDay) => isSameDay(completedDay, day));
  }

  @override
  Widget build(BuildContext context) {
    // 2. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        // 3. UI Theme: Removed colors, uses main.dart theme
        bottom: TabBar(
          controller: _tabController,
          // 4. UI Theme: Use primary cyan for indicator and labels
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
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

  // --- Tab 1: Calendar View (Section 7) ---
  Widget _buildCalendarView(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 5. UI Theme: Replaced Container with Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // REPLACED CalendarDatePicker with TableCalendar
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
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
                // 6. UI Theme: Styling for Dark Mode
                calendarStyle: CalendarStyle(
                  // Default text
                  defaultTextStyle:
                      TextStyle(color: theme.colorScheme.onSurface),
                  // Weekend text
                  weekendTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  // Text for other months
                  outsideTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  // Today's marker
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  // Selected day marker
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                // 7. UI Theme: Styling for Header
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: theme.textTheme.titleLarge!,
                  leftChevronIcon: Icon(Icons.chevron_left,
                      color: theme.colorScheme.onSurface),
                  rightChevronIcon: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface),
                ),
                // THIS IS WHERE THE GREEN CIRCLES ARE MADE
                calendarBuilders: CalendarBuilders(
                  // 8. UI Theme: Builder for completed days
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isDayCompleted(day)) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          // Use a more visible green
                          color: Colors.green.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            // Use white text
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  // 9. UI Theme: Today's date (if not completed)
                  todayBuilder: (context, day, focusedDay) {
                    if (_isDayCompleted(day)) {
                      // Handle if today is also completed
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      );
                    }
                    // Default "today" builder (cyan circle)
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
            // 10. UI Theme: Use light secondary text
            style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Skill Growth (Section 7) ---
  Widget _buildSkillGrowthView(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Text(
          'XP Growth Over Time',
          // 11. UI Theme: Use themed title
          style: theme.textTheme.titleLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 10),
        // 12. UI Theme: Chart placeholder as Card
        Card(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 13. UI Theme: Themed placeholder icon
                  Icon(Icons.bar_chart,
                      size: 50,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'XP Line Chart Placeholder',
                    // 14. UI Theme: Themed placeholder text
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
          // 15. UI Theme: Use themed title
          style: theme.textTheme.titleLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 15),
        // Displaying skill progress bars
        ...skillProgress.entries.map((entry) {
          return SkillProgressIndicator(
            skillName: entry.key,
            progress: entry.value,
          );
        }),
      ],
    );
  }
}

// Custom widget for displaying a single skill's progress
class SkillProgressIndicator extends StatelessWidget {
  final String skillName;
  final double progress; // Value from 0.0 to 100.0

  const SkillProgressIndicator({
    super.key,
    required this.skillName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // 16. UI Theme: Get theme from context
    final theme = Theme.of(context);
    // Semantic color (red-to-green) is great, keep it
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
                // 17. UI Theme: Use theme text style
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${progress.toInt()}/100',
                // Semantic color is good, keep it
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
              // 18. UI Theme: Use dark-friendly background
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}