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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
            onPressed: _loadSubmissions,
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
          child: RefreshIndicator(
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
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_none,
                                  size: 60, color: const Color(0xFF00BCD4).withOpacity(0.5)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'All caught up!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pending submissions to review.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // 6. Build the list from the API data
                return ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: submissions.length,
                  // AlwaysScrollable ensures pull-to-refresh works
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final logData = submissions[index];
                    final String drillName =
                        logData['drill'] ?? 'Unnamed Drill';
                    final String athleteId = logData['athleteId'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                                  size: 28, color: Colors.orange.shade400),
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drillName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 14,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Pending Review',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Review Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BCD4),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Review',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                // 7. Navigate and wait for return to refresh
                                await Navigator.of(context).pushNamed(
                                  '/review-submission',
                                  arguments: {
                                    'athleteId': athleteId,
                                    'logId': logData['id'],
                                    'logData': logData,
                                  },
                                );
                                _loadSubmissions();
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
          ),
        ),
      ),
    );
  }
}