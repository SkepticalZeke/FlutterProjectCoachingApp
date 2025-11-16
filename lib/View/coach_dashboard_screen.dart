import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORTS ⭐️
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  // ⭐️ GET FIREBASE INSTANCES ⭐️
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ UPDATED LOGOUT FUNCTION ⭐️
  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      // ⭐️ FIX: Navigates to the main '/login' screen ⭐️
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? currentUser = _auth.currentUser;

    // Handle case where user is somehow null (shouldn't happen if login works)
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error: No user logged in.'),
              TextButton(
                onPressed: _logout,
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
            // ⭐️ Use new logout function
            onPressed: _logout,
          ),
        ],
      ),
      // ⭐️ REPLACE MOCK BODY WITH A STREAMBUILDER ⭐️
      body: StreamBuilder<QuerySnapshot>(
        // 1. Create a Stream that finds all athletes linked to this coach
        stream: _firestore
            .collection('athletes')
            .where('coachUid', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // 2. Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Handle Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 4. Handle No Data State
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

          // 5. We have data! Get the list of athlete documents
          final athleteDocs = snapshot.data!.docs;

          // 6. Build the UI with the real data
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

                // ⭐️ Pass the real athlete list to the overview card
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

                // ⭐️ Map the real documents to the tile widget
                ...athleteDocs
                    .map((doc) => _buildAthleteTile(context, doc)),
              ],
            ),
          );
        },
      ),
      // ⭐️ ADDED FLOATING ACTION BUTTON ⭐️
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new screen
          Navigator.of(context).pushNamed('/create-drill');
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  // ⭐️ HELPER WIDGET UPDATED ⭐️
  // Now takes a List of real athlete documents
  Widget _buildOverviewCard(
      BuildContext context, List<QueryDocumentSnapshot> athletes) {
    // 1. Get real counts from the athlete list
    final completedCount = athletes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Check if 'progress' exists and is 1.0
      return data.containsKey('progress') && data['progress'] == 1.0;
    }).length;
    final totalCount = athletes.length;
    final theme = Theme.of(context);

    // 2. The rest of the UI is the same
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

  // ⭐️ HELPER WIDGET UPDATED ⭐️
  // Now takes a single athlete document
  Widget _buildAthleteTile(BuildContext context, QueryDocumentSnapshot athleteDoc) {
    // 1. Get the data from the document
    final athleteData = athleteDoc.data() as Map<String, dynamic>;
    final bool isComplete = athleteData['progress'] == 1.0;

    // 2. Build the tile using the real data
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
          // 3. ⭐️ IMPORTANT ⭐️
          // Pass the athlete's data *and* their unique Document ID
          // to the detail screen, so we can edit it later.
          Map<String, dynamic> dataToPass =
              athleteDoc.data() as Map<String, dynamic>;
          dataToPass['id'] =
              athleteDoc.id; // Add the document ID to the map

          Navigator.of(context).pushNamed(
            '/coach-athlete-detail',
            arguments: dataToPass,
          );
        },
      ),
    );
  }
}