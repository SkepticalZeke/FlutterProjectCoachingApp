import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/progress_viewmodel.dart';

/*
  VIEW (V)
  Refactored ProgressView with:
  - Gradient Background
  - Modern Calendar Styling
  - Enhanced Skill Progress Bars
  - Polished TabBar
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadData,
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Calendar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Growth'),
                    ],
                  ),
                ),
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
          child: TabBarView(
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
        ),
      ),
    );
  }

  // --- Tab 1: Calendar View (FutureBuilder) ---
  Widget _buildCalendarView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
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
                        TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                    weekendTextStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6)),
                    outsideTextStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.3)),
                    todayDecoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded),
                    ),
                    rightChevronIcon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded),
                    ),
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
                      // Custom today styling if not completed
                       return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Green circles mark days you completed at least one drill!',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Tab 2: Skill Growth (FutureBuilder) ---
  Widget _buildSkillGrowthView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.surface, colorScheme.surfaceContainerHighest.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insights_rounded,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'XP Analytics Coming Soon',
                        style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Track your progress week over week',
                        style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Skill Breakdown',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary
                ),
              ),
              const SizedBox(height: 16),
              
              if (skillProgress.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center_outlined, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No skill data yet',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                
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
    final colorScheme = theme.colorScheme;
    final Color progressColor =
        Color.lerp(Colors.orangeAccent, Colors.greenAccent.shade700, progress / 100)!;

    IconData getSkillIcon(String name) {
      switch (name.toLowerCase()) {
        case 'agility': return Icons.flash_on_rounded;
        case 'strength': return Icons.fitness_center_rounded;
        case 'cardio': return Icons.monitor_heart_rounded;
        default: return Icons.star_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: colorScheme.shadow.withOpacity(0.04),
             blurRadius: 10,
             offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(getSkillIcon(skillName), size: 20, color: progressColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    skillName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}