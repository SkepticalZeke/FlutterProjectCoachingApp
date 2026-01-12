import 'package:flutter/material.dart';
// Note: cloud_firestore import removed as we now use Maps/Lists
// Import the new ViewModel
import '../viewmodel/athlete_dashboard_viewmodel.dart';
// Import shared widget
import '../../../shared/widgets/skill_progress_bar.dart';

/*
  VIEW (V)
  Refactored AthleteDashboardView with:
  - Gradient Background & Transparent AppBar
  - Modern "Glassmorphism" feel for cards
  - Enhanced Streak & Profile visualization
  - Polished Task List for Drills
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We wrap the body in a FutureBuilder for the profile so we have the latest data
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        // Use the latest fetched data, or fallback to the data passed from the previous screen
        final liveAthleteData = profileSnapshot.data ?? widget.athleteData;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'CoachFitness Training',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false, // Disable back button
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadData,
                  tooltip: "Refresh Data",
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/settings', arguments: liveAthleteData);
                  },
                ),
              ),
            ],
          ),
          // 5. Gradient Background Container
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
                onRefresh: () async => _loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStreakCard(context, liveAthleteData),
                      const SizedBox(height: 20),
                      _buildAvatarSection(context, liveAthleteData),
                      const SizedBox(height: 24),
                      _buildActivityList(context, liveAthleteData),
                      const SizedBox(height: 30),
                      _buildAchievementsPreview(context, liveAthleteData),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 6. Bottom Nav Bar
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: colorScheme.surface,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
              showUnselectedLabels: true,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center_rounded), label: 'Drills'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Avatar'),
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_rounded), label: 'Rewards'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded), label: 'Progress'),
              ],
              currentIndex: 2, // Home
              onTap: (index) => _onItemTapped(index, liveAthleteData),
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildStreakCard(
      BuildContext context, Map<String, dynamic> athleteData) {
    final int streak = athleteData['streak'] ?? 0;
    final theme = Theme.of(context);
    
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
            color: Colors.orange.withOpacity(0.3),
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
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        'Days on Fire!',
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
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String athleteName = athleteData['name'] ?? 'Athlete';
    final String skillFocus = athleteData['skill_focus'] ?? 'General';
    final double currentXp = (athleteData['currentXp'] ?? 0.0).toDouble();
    final double requiredXp = (athleteData['requiredXp'] ?? 1000.0).toDouble();
    final int level = athleteData['level'] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                await Navigator.of(context)
                    .pushNamed('/avatar', arguments: athleteData);
                _loadData(); // Refresh on return
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      athleteName.substring(0,1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athleteName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(Icons.track_changes, size: 14, color: colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Focus: $skillFocus',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SkillProgressBar(
              currentXp: currentXp,
              requiredXp: requiredXp,
              level: level,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Today's Plan",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _drillsFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ));
            }
            
            // 2. Error State
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Error: ${snapshot.error}')),
                  ],
                ),
              );
            }

            final drills = snapshot.data ?? [];

            // 3. Empty State
            if (drills.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bedtime_rounded, size: 48, color: colorScheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No drills for today.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    Text('Rest up!', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ],
                ),
              );
            }

            // 4. Data State
            return Column(
              children: drills.map((drill) {
                final bool isCompleted = drill['completed'] ?? false;
                final String status = drill['status'] ?? '';
                
                // Color logic
                final Color iconColor = isCompleted 
                    ? Colors.green 
                    : (status == 'Pending Review' ? Colors.amber : colorScheme.primary);
                
                final Color bgColor = isCompleted
                    ? Colors.green.withOpacity(0.05)
                    : colorScheme.surface;

                final routeArgs = {
                  'athleteId': _viewModel.athleteId,
                  'drillId': drill['id'],
                  'drillData': drill,
                };

                Widget trailingWidget;
                if (status == 'Pending Review') {
                  trailingWidget = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: const Text("Pending", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                  );
                } else if (isCompleted) {
                  trailingWidget = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28);
                } else {
                  trailingWidget = ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        '/drill-detail',
                        arguments: routeArgs,
                      );
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(60, 36),
                      elevation: 0,
                    ),
                    child: const Text('Start'),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.04),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                    border: Border.all(
                      color: isCompleted ? Colors.green.withOpacity(0.2) : colorScheme.outlineVariant.withOpacity(0.3)
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconData(drill['iconData'] ?? 0xe28f, fontFamily: 'MaterialIcons'),
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      drill['name'] ?? 'Unnamed Drill',
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted 
                            ? theme.colorScheme.onSurface.withOpacity(0.5) 
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                         "${drill['xp'] ?? 0} XP Reward",
                         style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "Recent Badges",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context)
                .pushNamed('/rewards', arguments: athleteData),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBadge(context, Icons.star_rounded, '7-Day\nChamp', Colors.amber),
                Container(width: 1, height: 40, color: colorScheme.outlineVariant.withOpacity(0.5)),
                _buildBadge(context, Icons.bolt_rounded, 'Agility\nAce', Colors.blue),
                Container(width: 1, height: 40, color: colorScheme.outlineVariant.withOpacity(0.5)),
                _buildBadge(context, Icons.timeline_rounded, 'Cone\nMaster', Colors.deepPurple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String title, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
               BoxShadow(
                 color: color.withOpacity(0.2),
                 blurRadius: 8,
                 offset: const Offset(0, 2)
               )
            ]
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}