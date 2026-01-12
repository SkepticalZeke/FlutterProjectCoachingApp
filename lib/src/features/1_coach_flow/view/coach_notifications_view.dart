import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/coach_notifications_viewmodel.dart';

/*
  VIEW (V)
  Refactored CoachNotificationsView with:
  - Gradient Background
  - Modern Card Styling
  - Enhanced Empty State
  - Polished AppBar and Navigation
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

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadSubmissions,
              tooltip: "Refresh Notifications",
            ),
          )
        ],
      ),
      // 4. Wrap body in Gradient Container
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
            onRefresh: () async => _loadSubmissions(),
            // 5. Use FutureBuilder
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _submissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        TextButton(onPressed: _loadSubmissions, child: const Text("Retry")),
                      ],
                    ),
                  );
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
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle_outline_rounded,
                                  size: 80,
                                  color: Colors.green.withOpacity(0.6)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'All Caught Up!',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pending submissions to review.',
                              style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 16,
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: submissions.length,
                  physics: const AlwaysScrollableScrollPhysics(), 
                  itemBuilder: (context, index) {
                    final logData = submissions[index];
                    return _buildNotificationCard(context, logData);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> logData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String drillName = logData['drill'] ?? 'Unnamed Drill';
    final String athleteId = logData['athleteId'] ?? ''; 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await _navigateToReview(context, athleteId, logData);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drillName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Pending Review",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text('Review'),
                  onPressed: () async {
                    await _navigateToReview(context, athleteId, logData);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToReview(BuildContext context, String athleteId, Map<String, dynamic> logData) async {
    await Navigator.of(context).pushNamed(
      '/review-submission',
      arguments: {
        'athleteId': athleteId,
        'logId': logData['id'], 
        'logData': logData,
      },
    );
    _loadSubmissions();
  }
}