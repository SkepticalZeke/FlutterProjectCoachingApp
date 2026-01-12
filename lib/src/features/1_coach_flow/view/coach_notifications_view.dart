import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/coach_notifications_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class CoachNotificationsView extends StatefulWidget {
  const CoachNotificationsView({super.key});

  @override
  State<CoachNotificationsView> createState() => _CoachNotificationsViewState();
}

class _CoachNotificationsViewState extends State<CoachNotificationsView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachNotificationsViewModel();
  
  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    setState(() {
      _submissionsFuture = _viewModel.fetchPendingSubmissions();
    });
  }

  // 3. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          )
        ],
      ),
      // 4. Wrap body in RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async => _loadSubmissions(),
        // 5. Use FutureBuilder
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _submissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final submissions = snapshot.data ?? [];
            
            if (submissions.isEmpty) {
              // Scrollable empty state for pull-to-refresh support
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 80,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(height: 20),
                        Text('No pending submissions, all clear!',
                            style: TextStyle(
                                fontSize: 18,
                                color:
                                    theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              );
            }

            // 6. Build the list from the API data
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: submissions.length,
              // AlwaysScrollable ensures pull-to-refresh works
              physics: const AlwaysScrollableScrollPhysics(), 
              itemBuilder: (context, index) {
                final logData = submissions[index];
                final String drillName = logData['drill'] ?? 'Unnamed Drill';
                final String athleteId = logData['athleteId'] ?? ''; 

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.5), width: 1),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_top, color: Colors.amber, size: 30),
                    title: Text(
                      drillName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text('New submission is pending review.'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('Review'),
                      onPressed: () async {
                        // 7. Navigate and wait for return to refresh
                        await Navigator.of(context).pushNamed(
                          '/review-submission',
                          arguments: {
                            'athleteId': athleteId,
                            'logId': logData['id'], // Ensure ID is mapped in Repo
                            'logData': logData,
                          },
                        );
                        _loadSubmissions();
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}