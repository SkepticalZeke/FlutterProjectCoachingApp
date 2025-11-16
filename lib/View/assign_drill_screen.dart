import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignDrillScreen extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const AssignDrillScreen({super.key, required this.athleteData});

  @override
  State<AssignDrillScreen> createState() => _AssignDrillScreenState();
}

class _AssignDrillScreenState extends State<AssignDrillScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This function does the work
  Future<void> _assignDrill(Map<String, dynamic> drillData) async {
    final String? coachUid = _auth.currentUser?.uid;
    final String athleteId = widget.athleteData['id'];

    if (coachUid == null) {
      _showErrorSnackBar("Error: Not logged in.");
      return;
    }

    try {
      // 1. Get a reference to the athlete's 'todayDrills' subcollection
      final athleteDrillsRef = _firestore
          .collection('athletes')
          .doc(athleteId)
          .collection('todayDrills');

      // 2. Add the coach's drill data to that subcollection
      await athleteDrillsRef.add({
        'name': drillData['name'],
        'goal': drillData['goal'],
        'skillFocus': drillData['skillFocus'],
        'xp': drillData['xp'],
        'videoUrl': drillData['videoUrl'],
        'coachDrillId': drillData['id'], // Link to the original drill
        'assignedAt': FieldValue.serverTimestamp(),
        'completed': false,
        'iconData': 0xe28f, // Default icon (fitness_center)
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Assigned "${drillData['name']}" to ${widget.athleteData['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to the detail screen
      }
    } catch (e) {
      _showErrorSnackBar("Error assigning drill: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? coachUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Drill to ${widget.athleteData['name']}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream the coach's custom drills
        stream: _firestore
            .collection('coaches')
            .doc(coachUid)
            .collection('drills')
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
                  Icon(Icons.video_call_outlined,
                      size: 60,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text('No custom drills found.'),
                  Text(
                    'Go back and create one first!',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          // 2. We have drills! Build the list.
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              final drillData = doc.data() as Map<String, dynamic>;
              drillData['id'] = doc.id; // Add the document ID

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.video_library,
                      color: theme.colorScheme.primary),
                  title: Text(
                    drillData['name'] ?? 'Unnamed Drill',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Skill: ${drillData['skillFocus']} | XP: ${drillData['xp']}',
                  ),
                  trailing: const Icon(Icons.add_task),
                  onTap: () {
                    // 3. Assign this drill when tapped
                    _assignDrill(drillData);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}