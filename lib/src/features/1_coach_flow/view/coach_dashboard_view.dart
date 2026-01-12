import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/coach_dashboard_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class CoachDashboardView extends StatefulWidget {
  const CoachDashboardView({super.key});

  @override
  State<CoachDashboardView> createState() => _CoachDashboardViewState();
}

class _CoachDashboardViewState extends State<CoachDashboardView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachDashboardViewModel();
  
  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _athletesFuture;

  @override
  void initState() {
    super.initState();
    // Load initial data
    _loadAthletes();
  }

  void _loadAthletes() {
    setState(() {
      _athletesFuture = _viewModel.fetchAthletes();
    });
  }

  // 3. The View handles the logout logic
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

    // Handle case where user isn't logged in
    if (_viewModel.coachUid == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error: No user logged in.'),
              TextButton(
                onPressed: _handleLogout,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        automaticallyImplyLeading: false, // Disable back button
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed('/coach-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      // 4. Wrap body in RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async => _loadAthletes(),
        // 5. Use FutureBuilder
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _athletesFuture,
          builder: (context, snapshot) {
            // Handle Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Handle Error State
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final athletes = snapshot.data ?? [];

            // Handle No Data State
            if (athletes.isEmpty) {
              // Wrap in SingleChildScrollView/ListView so Pull-to-Refresh works on empty state
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        const Text('No athletes found.'),
                        Text(
                          'Add your first athlete from the Actions menu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Build the UI with the real data
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Coach!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Pass the real athlete list to the overview card
                  _buildOverviewCard(context, athletes),
                  const SizedBox(height: 30),
                  Text(
                    'Athletes Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Map the real documents to the tile widget
                  ...athletes.map((athleteData) => _buildAthleteTile(context, athleteData)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Actions'),
      ),
    );
  }

  // 6. Updated Helpers to use Map/List instead of QuerySnapshot
  Widget _buildOverviewCard(
      BuildContext context, List<Map<String, dynamic>> athletes) {
    
    final completedCount = athletes.where((data) {
      return (data['progress'] ?? 0.0) == 1.0;
    }).length;
    
    final totalCount = athletes.length;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Summary',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green[600]),
              title: const Text('Training Completion'),
              trailing: Text(
                '$completedCount / $totalCount',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people, color: theme.colorScheme.primary),
              title: const Text('Total Linked Athletes'),
              trailing: Text(
                '$totalCount',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteTile(
      BuildContext context, Map<String, dynamic> athleteData) {
    final bool isComplete = (athleteData['progress'] ?? 0.0) == 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isComplete ? Colors.green : Colors.grey[700],
          child: Icon(
            isComplete ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          athleteData['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${athleteData['status'] ?? 'N/A'}',
              style: TextStyle(
                  color: isComplete ? Colors.green[400] : Colors.red[400]),
            ),
            Text('Current Streak: ${athleteData['streak'] ?? 0} days'),
            Text('Level: ${athleteData['level'] ?? 1}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        onTap: () async {
          // Navigate and wait for return to refresh data
          await Navigator.of(context).pushNamed(
            '/coach-athlete-detail',
            arguments: athleteData,
          );
          _loadAthletes();
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Coach Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Option 1: Add Custom Drill
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.video_library, color: Colors.white),
                ),
                title: const Text('Create New Drill'),
                subtitle: const Text('Upload a video and set XP'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/create-drill');
                },
              ),

              // Option 2: Add New Athlete
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text('Add New Athlete'),
                subtitle: const Text('Create a profile for a new player'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddAthleteDialog();
                },
              ),

              // Option 3: Mass Assign
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.playlist_add_check, color: Colors.white),
                ),
                title: const Text('Mass Assign Drill'),
                subtitle: const Text('Assign a drill to multiple athletes'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mass Assign Coming Soon!')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAthleteDialog() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Athlete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Athlete Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(labelText: '4-Digit PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  pinController.text.length == 4) {
                Navigator.pop(ctx); // Close dialog
                
                // Call ViewModel
                final success = await _viewModel.addNewAthlete(
                  nameController.text.trim(),
                  pinController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Athlete added successfully!'
                          : 'Failed to add athlete.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  if (success) {
                    _loadAthletes(); // Refresh list immediately
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}