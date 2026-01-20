import 'package:flutter/material.dart';
import '../viewmodel/coach_dashboard_viewmodel.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
            onPressed: _refreshAll,
          ),
          const SizedBox(width: 8),
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
              child:
                  const Icon(Icons.logout, size: 20, color: Colors.redAccent),
            ),
            onPressed: _handleLogout,
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
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildTeamTab(), // Tab 0
              _buildDrillsTab(), // Tab 1
              _buildNotificationsTab(), // Tab 2
            ],
          ),
        ),
      ),
      // DYNAMIC FAB
      floatingActionButton: _buildFab(theme),
      // BOTTOM NAVIGATION
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
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: theme.primaryColor.withOpacity(0.2),
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
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'My Team';
      case 1:
        return 'Drill Library';
      case 2:
        return 'Pending Reviews';
      default:
        return 'Dashboard';
    }
  }

  // =======================================================
  // TAB 0: TEAM LIST
  // =======================================================
  Widget _buildTeamTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
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
            padding: const EdgeInsets.all(20),
            itemCount: athletes.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              final name = athlete['name'] ?? 'Unknown';
              final firstLetter =
                  name.isNotEmpty ? name[0].toUpperCase() : '?';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await Navigator.pushNamed(
                          context, '/coach-athlete-detail',
                          arguments: athlete);
                      _refreshAll();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              firstLetter,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00BCD4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Level ${athlete['level']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =======================================================
  // TAB 1: DRILL LIBRARY
  // =======================================================
  Widget _buildDrillsTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
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
            padding: const EdgeInsets.all(20),
            itemCount: drills.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final drill = drills[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Video Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.play_circle_fill,
                            size: 28, color: Colors.deepPurple.shade400),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drill['name'] ?? 'Untitled Drill',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  drill['skillFocus'] ?? 'General',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.circle,
                                    size: 4, color: Colors.grey.shade300),
                                const SizedBox(width: 8),
                                Text(
                                  '${drill['xp']} XP',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Edit Icon
                      IconButton(
                        icon: Icon(Icons.edit,
                            size: 20, color: Colors.grey.shade400),
                        onPressed: () {
                          // Optional: Navigate to edit drill
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =======================================================
  // TAB 2: NOTIFICATIONS (Pending Reviews)
  // =======================================================
  Widget _buildNotificationsTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
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
            padding: const EdgeInsets.all(20),
            itemCount: submissions.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final sub = submissions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.hourglass_top,
                            size: 24, color: Colors.orange.shade400),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub['drill'] ?? 'Drill Submission',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waiting for review',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Review Button
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            '/review-submission',
                            arguments: {
                              'athleteId': sub['athleteId'],
                              'logId': sub['id'],
                              'logData': sub,
                            },
                          );
                          _refreshAll();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Review"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =======================================================
  // HELPER WIDGETS
  // =======================================================

  // Floating Action Button Logic
  Widget? _buildFab(ThemeData theme) {
    if (_selectedIndex == 0) {
      // TAB 0: Add Athlete
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF00BCD4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showLinkAthleteDialog(context),
          label: const Text('Connect'),
          icon: const Icon(Icons.person_add),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      );
    } else if (_selectedIndex == 1) {
      // TAB 1: Create Drill
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.deepPurple,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.pushNamed(context, '/create-drill');
            _refreshAll();
          },
          label: const Text('New Drill'),
          icon: const Icon(Icons.videocam),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: const Color(0xFF00BCD4).withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // DIALOG: Uses the Link Code
  void _showLinkAthleteDialog(BuildContext context) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connect Athlete', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ask your athlete for their 6-character Connection Code.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Connection Code (e.g. X7K9P2)',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (codeController.text.length >= 4) {
                Navigator.pop(ctx);
                final success =
                    await _viewModel.linkAthlete(codeController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        success ? 'Linked successfully!' : 'Failed. Check code.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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