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
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text('No athletes found.'),
                  Text(
                    'Add your first athlete from the Registration screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-drill');
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
}