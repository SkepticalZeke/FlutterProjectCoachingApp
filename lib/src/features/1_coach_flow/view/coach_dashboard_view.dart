import 'package:flutter/material.dart';
import '../viewmodel/coach_dashboard_viewmodel.dart';
// Import Create Drill View for navigation
import 'create_drill_view.dart';
// Import Review View for navigation
import 'review_submission_view.dart';
import 'coach_athlete_detail_view.dart';

class CoachDashboardView extends StatefulWidget {
  const CoachDashboardView({super.key});

  @override
  State<CoachDashboardView> createState() => _CoachDashboardViewState();
}

class _CoachDashboardViewState extends State<CoachDashboardView> {
  final _viewModel = CoachDashboardViewModel();
  
  // Controls which tab is active (0: Team, 1: Drills, 2: Alerts)
  int _selectedIndex = 0;

  // Data Futures
  late Future<List<Map<String, dynamic>>> _athletesFuture;
  late Future<List<Map<String, dynamic>>> _drillsFuture;
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  // Refresh all data tabs
  void _refreshAll() {
    setState(() {
      _athletesFuture = _viewModel.fetchAthletes();
      _drillsFuture = _viewModel.fetchCoachDrills();
      _notificationsFuture = _viewModel.fetchPendingSubmissions();
    });
  }

  void _handleLogout() async {
    await _viewModel.logout();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/role-selection', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          )
        ],
      ),
      // DYNAMIC BODY BASED ON TAB
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTeamTab(),          // Tab 0
          _buildDrillsTab(),        // Tab 1
          _buildNotificationsTab(), // Tab 2
        ],
      ),
      // DYNAMIC FAB (Changes function based on Tab)
      floatingActionButton: _buildFab(theme),
      // BOTTOM NAVIGATION
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Drills',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'My Team';
      case 1: return 'Drill Library';
      case 2: return 'Pending Reviews';
      default: return 'Dashboard';
    }
  }

  // =======================================================
  // TAB 0: TEAM LIST (With New Link Logic)
  // =======================================================
  Widget _buildTeamTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _athletesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final athletes = snapshot.data ?? [];

        if (athletes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.group_add,
            message: "No athletes yet.\nTap '+' to connect via code.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: athletes.length,
          itemBuilder: (context, index) {
            final athlete = athletes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(athlete['name']?[0] ?? '?'),
                ),
                title: Text(athlete['name'] ?? 'Unknown'),
                subtitle: Text('Level ${athlete['level']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.pushNamed(
                    context, 
                    '/coach-athlete-detail', 
                    arguments: athlete
                  );
                  _refreshAll();
                },
              ),
            );
          },
        );
      },
    );
  }

  // =======================================================
  // TAB 1: DRILL LIBRARY
  // =======================================================
  Widget _buildDrillsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _drillsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final drills = snapshot.data ?? [];

        if (drills.isEmpty) {
          return _buildEmptyState(
            icon: Icons.video_call,
            message: "No drills created.\nRecord one to get started!",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drills.length,
          itemBuilder: (context, index) {
            final drill = drills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.play_circle_fill, size: 40, color: Colors.blue),
                title: Text(drill['name'] ?? 'Untitled Drill'),
                subtitle: Text('${drill['skillFocus']} • ${drill['xp']} XP'),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  // =======================================================
  // TAB 2: NOTIFICATIONS (Pending Reviews)
  // =======================================================
  Widget _buildNotificationsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final submissions = snapshot.data ?? [];

        if (submissions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            message: "All caught up!\nNo pending reviews.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                title: Text(sub['drill'] ?? 'Drill Submission'),
                subtitle: const Text('Waiting for review'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context, 
                      '/review-submission',
                      arguments: {
                        'athleteId': sub['athleteId'],
                        'logId': sub['id'],
                        'logData': sub,
                      }
                    );
                    _refreshAll();
                  },
                  child: const Text("Review"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =======================================================
  // HELPER WIDGETS
  // =======================================================
  
  // Floating Action Button Logic
  Widget? _buildFab(ThemeData theme) {
    if (_selectedIndex == 0) {
      // TAB 0: Add Athlete
      return FloatingActionButton.extended(
        onPressed: () => _showLinkAthleteDialog(context),
        label: const Text('Connect Athlete'),
        icon: const Icon(Icons.person_add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else if (_selectedIndex == 1) {
      // TAB 1: Create Drill
      return FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/create-drill');
          _refreshAll();
        },
        label: const Text('New Drill'),
        icon: const Icon(Icons.videocam),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
      );
    }
    // TAB 2: No Fab
    return null;
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // NEW DIALOG: Uses the Link Code
  void _showLinkAthleteDialog(BuildContext context) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect Athlete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ask your athlete for their 6-character Connection Code.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Connection Code (e.g. X7K9P2)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.length >= 4) {
                Navigator.pop(ctx);
                final success = await _viewModel.linkAthlete(codeController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Linked successfully!' : 'Failed. Check code.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ));
                  if (success) _refreshAll();
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}