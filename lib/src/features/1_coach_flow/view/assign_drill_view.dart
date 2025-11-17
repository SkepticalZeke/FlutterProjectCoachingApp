import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new ViewModel
import '../viewmodel/assign_drill_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class AssignDrillView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const AssignDrillView({super.key, required this.athleteData});

  @override
  State<AssignDrillView> createState() => _AssignDrillViewState();
}

class _AssignDrillViewState extends State<AssignDrillView> {
  // 1. The View owns its ViewModel
  final _viewModel = AssignDrillViewModel();

  // 2. "handle" function now calls the ViewModel
  Future<void> _assignDrill(Map<String, dynamic> drillData) async {
    bool success = await _viewModel.assignDrill(
      athleteId: widget.athleteData['id'],
      drillData: drillData,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Assigned "${drillData['name']}" to ${widget.athleteData['name']}!'
              : 'Error assigning drill.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      Navigator.of(context).pop(); // Go back to the detail screen
    }
  }

  // 3. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Drill to ${widget.athleteData['name']}'),
      ),
      // 4. Listen to the stream from the ViewModel
      body: StreamBuilder<QuerySnapshot>(
        stream: _viewModel.coachDrillsStream,
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

          // 5. We have drills! Build the list.
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
                    // 6. Assign this drill when tapped
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