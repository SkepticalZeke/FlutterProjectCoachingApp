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
  final bool embedded; // When true, no Scaffold wrapper (used in shell)
  const ProgressView({super.key, required this.athleteData, this.embedded = false});

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Progress',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.refresh, size: 20, color: Color(0xFF00BCD4)),
            ),
            onPressed: _loadData,
          ),
          const SizedBox(width: 16),
        ],
      ),
      // DARK BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom Tab Bar ---
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month),
                          SizedBox(width: 8),
                          Text('Calendar'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart),
                          SizedBox(width: 8),
                          Text('Skill Growth'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Tab Views ---
              Expanded(
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
            ],
          ),
        ),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
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
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.grey.shade400),
                    outsideTextStyle:
                        TextStyle(color: Colors.grey.shade700),
                    todayDecoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                        color: theme.primaryColor, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
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
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Training Completed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Extracted widget for cleaner code
  Widget _buildCompletedDayMarker(ThemeData theme, DateTime day) {
    return Center(
      child: Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
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
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'XP Growth',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bar_chart_rounded,
                          size: 40, color: Color(0xFF00BCD4)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Training stats accumulating...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (skillProgress.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Complete drills to see your skills grow!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
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
      },
    );
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
    // Interpolate color based on progress (Red -> Green)
    final Color progressColor =
        HSVColor.fromAHSV(1.0, (progress / 100) * 120, 0.8, 0.9).toColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}