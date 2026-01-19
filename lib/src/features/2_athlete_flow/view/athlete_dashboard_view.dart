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
  final bool embedded; // When true, no Scaffold/BottomNav (used in shell)
  const AthleteDashboardView({super.key, required this.athleteData, this.embedded = false});

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
    final theme = Theme.of(context);

    // We wrap the body in a FutureBuilder for the profile so we have the latest data (like XP)
    // available for the whole screen context if needed.
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        // Use the latest fetched data, or fallback to the data passed from the previous screen
        final liveAthleteData = profileSnapshot.data ?? widget.athleteData;

        // Build the main content
        final content = Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF121212),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStreakCard(context, liveAthleteData),
                    const SizedBox(height: 24),
                    _buildAvatarSection(context, liveAthleteData),
                    const SizedBox(height: 32),
                    _buildActivityList(context, liveAthleteData),
                    const SizedBox(height: 32),
                    _buildAchievementsPreview(context, liveAthleteData),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );

        // If embedded in shell, return content without Scaffold
        if (widget.embedded) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text(
                'CoachFitness',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
                    onPressed: _loadData,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFF00BCD4)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/settings',
                          arguments: liveAthleteData);
                    },
                  ),
                ),
              ],
            ),
            body: content,
          );
        }

        // Standard mode with full Scaffold and bottom nav
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'CoachFitness',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                fontStyle: FontStyle.italic,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            actions: [
              // Manual Refresh Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
                  onPressed: _loadData,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFF00BCD4)),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/settings',
                        arguments: liveAthleteData);
                  },
                ),
              ),
            ],
          ),
          body: content,
          // 6. Bottom Nav Bar - Updated styling
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF1E1E1E),
              selectedItemColor: theme.primaryColor,
              unselectedItemColor: Colors.grey.shade600,
              showUnselectedLabels: true,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center), label: 'Drills'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Avatar'),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: 'Rewards'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: 'Progress'),
              ],
              currentIndex: 2, // Home
              onTap: (index) => _onItemTapped(index, liveAthleteData),
            ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Streak',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      'Days!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
    final String athleteName =
        athleteData['name'] ?? 'Athlete'; // Display Name
    final String connectionCode = athleteData['connectionCode'] ?? '----';
    final String skillFocus = athleteData['skill_focus'] ?? 'General';
    final double currentXp = (athleteData['currentXp'] ?? 0.0).toDouble();
    final double requiredXp =
        (athleteData['requiredXp'] ?? 1000.0).toDouble();
    final int level = athleteData['level'] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              await Navigator.of(context)
                  .pushNamed('/avatar', arguments: athleteData);
              _loadData(); // Refresh on return
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Avatar Circle
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.primaryColor.withOpacity(0.3), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: theme.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.person,
                          size: 40, color: theme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. USERNAME (Login ID) - Top
                        Text(
                          '@$username',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 2. DISPLAY NAME - Below Username
                        Text(
                          athleteName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 3. CONNECTION CODE & FOCUS
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.shade600)),
                              child: Text(
                                'CODE: $connectionCode',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF00BCD4).withOpacity(0.5))),
                              child: Text(
                                skillFocus,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00BCD4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          
          // Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SkillProgressBar(
              currentXp: currentXp,
              requiredXp: requiredXp,
              level: level,
            ),
          ),
        ],
      ),
    );
  }

  // 7. Replaced StreamBuilder with FutureBuilder for Drills
  Widget _buildActivityList(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Plan",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              DateTime.now().toString().substring(0, 10),
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _drillsFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ));
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Error: ${snapshot.error}')),
                  ],
                ),
              );
            }

            final drills = snapshot.data ?? [];

            // 3. Empty State
            if (drills.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bedtime, size: 40, color: Colors.purple.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Rest Day!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.purple.shade300),
                    ),
                    Text(
                      'No drills assigned for today.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
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

                // Determine trailing widget
                Widget trailingWidget;
                if (status == 'Pending Review') {
                  trailingWidget = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text('Pending',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700)),
                      ],
                    ),
                  );
                } else if (isCompleted) {
                  trailingWidget =
                      const Icon(Icons.check_circle, color: Colors.green, size: 28);
                } else {
                  trailingWidget = ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        '/drill-detail',
                        arguments: routeArgs,
                      );
                      _loadData(); // Refresh upon return
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Start'),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.2)
                            : theme.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(drill['iconData'] ?? 0xe28f,
                            fontFamily: 'MaterialIcons'),
                        color: isCompleted
                            ? Colors.green
                            : theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      drill['name'] ?? 'Unnamed Drill',
                      style: TextStyle(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? Colors.grey.shade600
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: isCompleted
                        ? null
                        : Text(
                            "${drill['xp']} XP",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Latest Achievements",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.of(context)
              .pushNamed('/rewards', arguments: athleteData),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge(Icons.star, '7-Day Streak', Colors.amber),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade700),
                _buildBadge(Icons.speed, 'Agility Ace', Colors.blue),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade700),
                _buildBadge(
                    Icons.timeline, 'Cone Master', Colors.deepPurple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String title, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}