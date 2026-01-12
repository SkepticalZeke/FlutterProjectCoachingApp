import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 2. The View handles the logout logic (calling the ViewModel)
  void _handleLogout() async {
    await _viewModel.logout();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // This handles the case where the user isn't logged in
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed('/coach-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout, // Call our new handler
          ),
        ],
      ),
      // 3. The body is now a StreamBuilder listening to the ViewModel
      body: StreamBuilder<QuerySnapshot>(
        stream: _viewModel.athletesStream,
        builder: (context, snapshot) {
          // Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Handle Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Handle No Data State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 60,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  const Text('No athletes found.'),
                  Text(
                    'Add your first athlete from the Registration screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            );
          }

          // We have data! Get the list of athlete documents
          final athleteDocs = snapshot.data!.docs;

          // Build the UI with the real data
          return SingleChildScrollView(
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
                _buildOverviewCard(context, athleteDocs),
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
                ...athleteDocs.map((doc) => _buildAthleteTile(context, doc)),
              ],
            ),
          );
        },
      ),
      // 4. FAB is unchanged
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Actions'),
      ),
    );
  }

  // 5. Helper widgets are now part of the View
  Widget _buildOverviewCard(
      BuildContext context, List<QueryDocumentSnapshot> athletes) {
    final completedCount = athletes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('progress') && data['progress'] == 1.0;
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
      BuildContext context, QueryDocumentSnapshot athleteDoc) {
    final athleteData = athleteDoc.data() as Map<String, dynamic>;
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
          athleteData['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${athleteData['status']}',
              style: TextStyle(
                  color: isComplete ? Colors.green[400] : Colors.red[400]),
            ),
            Text('Current Streak: ${athleteData['streak']} days'),
            Text('Level: ${athleteData['level']}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        onTap: () {
          // 6. Navigation is handled by the View
          Map<String, dynamic> dataToPass =
              athleteDoc.data() as Map<String, dynamic>;
          dataToPass['id'] = athleteDoc.id; // Add the document ID

          Navigator.of(context).pushNamed(
            '/coach-athlete-detail',
            arguments: dataToPass,
          );
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
                  Navigator.pop(ctx); // Close sheet
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
                  Navigator.pop(ctx); // Close sheet
                  _showAddAthleteDialog();
                },
              ),

              // Option 3: Mass Assign (Placeholder for now)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.playlist_add_check, color: Colors.white),
                ),
                title: const Text('Mass Assign Drill'),
                subtitle: const Text('Assign a drill to multiple athletes'),
                onTap: () {
                  Navigator.pop(ctx);
                  // For now, we show a SnackBar. 
                  // To implement fully, you'd need a multi-select screen.
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