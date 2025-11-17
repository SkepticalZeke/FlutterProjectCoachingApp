import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 2. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      // 3. Listen to the stream from the ViewModel
      body: StreamBuilder<QuerySnapshot>(
        stream: _viewModel.pendingSubmissionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('No pending submissions, all clear!',
                      style: TextStyle(
                          fontSize: 18,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            );
          }

          // 4. We have submissions! Build the list.
          return ListView(
            padding: const EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((doc) {
              final logData = doc.data() as Map<String, dynamic>;
              final String drillName = logData['drill'] ?? 'Unnamed Drill';
              // We added athleteId to the log, so we can get it here
              final String athleteId = logData['athleteId'] ?? ''; 

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1),
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
                    onPressed: () {
                      // 5. Navigate to the Review screen with all data
                      Navigator.of(context).pushNamed(
                        '/review-submission',
                        arguments: {
                          'athleteId': athleteId,
                          'logId': doc.id,
                          'logData': logData,
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}