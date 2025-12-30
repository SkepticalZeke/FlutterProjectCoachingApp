import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    // 3. Initialize the ViewModel with the athlete's data
    _viewModel.initialize(widget.athleteData);
    // We don't need to listen, as StreamBuilders will update the UI
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
        break;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoachFitness Training'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/settings', arguments: widget.athleteData);
            },
          ),
        ],
      ),
      // 5. Main body is a StreamBuilder listening to the ViewModel
      body: StreamBuilder<DocumentSnapshot>(
        stream: _viewModel.athleteStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Athlete data not found.'));
          }

          final liveAthleteData =
              snapshot.data!.data() as Map<String, dynamic>;
          // Add the ID to the map for navigation
          liveAthleteData['id'] = snapshot.data!.id;

          return SingleChildScrollView(
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
          );
        },
      ),
      // 6. Bottom Nav Bar also uses a StreamBuilder
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
          stream: _viewModel.athleteStream,
          builder: (context, snapshot) {
            // Get live data to pass to the nav bar
            Map<String, dynamic> liveData = widget.athleteData; // Default
            if (snapshot.hasData && snapshot.data!.exists) {
              liveData = snapshot.data!.data() as Map<String, dynamic>;
              liveData['id'] = snapshot.data!.id;
            }

            return BottomNavigationBar(
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
              onTap: (index) => _onItemTapped(index, liveData),
            );
          }),
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

  Widget _buildAvatarSection(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);
    final String athleteName = athleteData['name'] ?? 'Athlete';
    final String skillFocus = athleteData['skill_focus'] ?? 'General';
    final double currentXp = (athleteData['currentXp'] ?? 0.0).toDouble();
    final double requiredXp = (athleteData['requiredXp'] ?? 1000.0).toDouble();
    final int level = athleteData['level'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.of(context)
              .pushNamed('/avatar', arguments: athleteData),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athleteName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Focus: $skillFocus',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
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

  // 7. This helper is now a StreamBuilder listening to the ViewModel
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
        StreamBuilder<QuerySnapshot>(
          stream: _viewModel.todayDrillsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No drills assigned for today.'),
                  subtitle: Text('Check back later!'),
                ),
              );
            }

            final drillDocs = snapshot.data!.docs;

            return Column(
              children: drillDocs.map((doc) {
                final drill = doc.data() as Map<String, dynamic>;
                final bool isCompleted = drill['completed'] ?? false;
                final String status = drill['status'] ?? '';

                // Create the map to pass to drill detail
                final routeArgs = {
                  'athleteId': _viewModel.athleteId,
                  'drillId': doc.id,
                  'drillData': drill,
                };

                // 8. Determine what the trailing widget should be
                Widget trailingWidget;
                if (status == 'Pending Review') {
                  trailingWidget =
                      const Icon(Icons.hourglass_top, color: Colors.amber);
                } else if (isCompleted) {
                  trailingWidget =
                      const Icon(Icons.check_circle, color: Colors.green);
                } else {
                  trailingWidget = ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/drill-detail',
                        arguments: routeArgs,
                      );
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