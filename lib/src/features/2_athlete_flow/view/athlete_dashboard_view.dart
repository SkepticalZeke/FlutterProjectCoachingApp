import 'package:flutter/material.dart';
// Note: cloud_firestore import removed as we now use Maps/Lists
// Import the new ViewModel
import '../viewmodel/athlete_dashboard_viewmodel.dart';
// Import shared widget
import '../../../shared/widgets/skill_progress_bar.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class AthleteDashboardView extends StatefulWidget {
  // 1. It still receives the athleteData map from navigation
  final Map<String, dynamic> athleteData;
  const AthleteDashboardView({super.key, required this.athleteData});

  @override
  State<AthleteDashboardView> createState() => _AthleteDashboardViewState();
}

class _AthleteDashboardViewState extends State<AthleteDashboardView> {
  // 2. The View owns its ViewModel
  final _viewModel = AthleteDashboardViewModel();
  
  // 3. State variables for our API data
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _drillsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize ViewModel
    _viewModel.initialize(widget.athleteData);
    // Load initial data
    _loadData();
  }

  // Helper to fetch data from API
  void _loadData() {
    setState(() {
      _profileFuture = _viewModel.getAthleteProfile();
      _drillsFuture = _viewModel.getTodayDrills();
    });
  }

  // 4. Navigation is a View concern
  void _onItemTapped(int index, Map<String, dynamic> athleteData) {
    // Pass the athleteData (which includes the ID) to all other screens
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/training', arguments: athleteData);
        break;
      case 1:
        Navigator.of(context).pushNamed('/avatar', arguments: athleteData);
        break;
      case 2:
        break; // Current page
      case 3:
        Navigator.of(context).pushNamed('/rewards', arguments: athleteData);
        break;
      case 4:
        Navigator.of(context).pushNamed('/progress', arguments: athleteData);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the body in a FutureBuilder for the profile so we have the latest data (like XP)
    // available for the whole screen context if needed.
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        // Use the latest fetched data, or fallback to the data passed from the previous screen
        final liveAthleteData = profileSnapshot.data ?? widget.athleteData;

        return Scaffold(
          appBar: AppBar(
            title: const Text('CoachFitness Training'),
            elevation: 0,
            actions: [
              // Manual Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/settings', arguments: liveAthleteData);
                },
              ),
            ],
          ),
          // 5. Pull-to-Refresh wraps the scrollable content
          body: RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakCard(context, liveAthleteData),
                  const SizedBox(height: 20),
                  _buildAvatarSection(context, liveAthleteData),
                  const SizedBox(height: 20),
                  _buildActivityList(context, liveAthleteData),
                  const SizedBox(height: 30),
                  _buildAchievementsPreview(context, liveAthleteData),
                ],
              ),
            ),
          ),
          // 6. Bottom Nav Bar - Updated to use liveAthleteData directly
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center), label: 'Drills'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Avatar'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events), label: 'Rewards'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'Progress'),
            ],
            currentIndex: 2, // Home
            onTap: (index) => _onItemTapped(index, liveAthleteData),
          ),
        );
      },
    );
  }

  // --- Helper Widgets (Dumb UI) ---

  Widget _buildStreakCard(
      BuildContext context, Map<String, dynamic> athleteData) {
    final int streak = athleteData['streak'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary, // Cyan
            Colors.cyan.shade700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.amber, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Streak:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$streak Days!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ⭐️ UPDATED SECTION: Displays Username, then Display Name, then Code
  Widget _buildAvatarSection(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);

    // Data Extraction
    final String username = athleteData['username'] ?? ''; // Extract Username
    final String athleteName = athleteData['name'] ?? 'Athlete'; // Display Name
    final String connectionCode = athleteData['connectionCode'] ?? '----';
    final String skillFocus = athleteData['skill_focus'] ?? 'General';
    final double currentXp = (athleteData['currentXp'] ?? 0.0).toDouble();
    final double requiredXp = (athleteData['requiredXp'] ?? 1000.0).toDouble();
    final int level = athleteData['level'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            await Navigator.of(context)
                .pushNamed('/avatar', arguments: athleteData);
            _loadData(); // Refresh on return
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person,
                        size: 50, color: theme.colorScheme.onPrimary),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. USERNAME (Login ID) - Top
                      Text(
                        '@$username', 
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // 2. DISPLAY NAME - Below Username
                      Text(
                        athleteName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          height: 1.1, // Slight line height adjustment
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 3. CONNECTION CODE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3))),
                        child: Text(
                          'CODE: $connectionCode',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 4. FOCUS
                      Text(
                        'Focus: $skillFocus',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        SkillProgressBar(
          currentXp: currentXp,
          requiredXp: requiredXp,
          level: level,
        ),
      ],
    );
  }
  
  // 7. Replaced StreamBuilder with FutureBuilder for Drills
  Widget _buildActivityList(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Training Plan",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _drillsFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ));
            }
            
            // 2. Error State
            if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  title: const Text('Error loading drills'),
                  subtitle: Text('${snapshot.error}'),
                  leading: const Icon(Icons.error, color: Colors.red),
                ),
              );
            }

            final drills = snapshot.data ?? [];

            // 3. Empty State
            if (drills.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No drills assigned for today.'),
                  subtitle: Text('Check back later!'),
                ),
              );
            }

            // 4. Data State
            return Column(
              children: drills.map((drill) {
                final bool isCompleted = drill['completed'] ?? false;
                final String status = drill['status'] ?? '';

                // Create the map to pass to drill detail
                final routeArgs = {
                  'athleteId': _viewModel.athleteId,
                  'drillId': drill['id'], // Ensure ID is part of the map from VM
                  'drillData': drill,
                };

                // Determine what the trailing widget should be
                Widget trailingWidget;
                if (status == 'Pending Review') {
                  trailingWidget =
                      const Icon(Icons.hourglass_top, color: Colors.amber);
                } else if (isCompleted) {
                  trailingWidget =
                      const Icon(Icons.check_circle, color: Colors.green);
                } else {
                  trailingWidget = ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        '/drill-detail',
                        arguments: routeArgs,
                      );
                      _loadData(); // Refresh upon return
                    },
                    child: const Text('Start'),
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      IconData(drill['iconData'] ?? 0xe28f,
                          fontFamily: 'MaterialIcons'),
                      color: isCompleted
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                    title: Text(
                      drill['name'] ?? 'Unnamed Drill',
                      style: TextStyle(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: trailingWidget,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementsPreview(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Achievements",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.of(context)
              .pushNamed('/rewards', arguments: athleteData),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(Icons.star, '7-Day Champion!', Colors.amber),
              _buildBadge(Icons.speed, 'Agility Ace', Colors.blue),
              _buildBadge(Icons.timeline, 'Cone Master', Colors.deepPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String title, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}