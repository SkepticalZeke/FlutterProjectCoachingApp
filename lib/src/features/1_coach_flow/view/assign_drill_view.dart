import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
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
  
  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _drillsFuture;

  @override
  void initState() {
    super.initState();
    // Load data initially
    _loadDrills();
  }

  void _loadDrills() {
    setState(() {
      _drillsFuture = _viewModel.fetchCoachDrills();
    });
  }

  // 3. "handle" function now calls the ViewModel
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
      if (success) {
        Navigator.of(context).pop(); // Go back to the detail screen on success
      }
    }
  }

  // 4. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Drill to ${widget.athleteData['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrills,
          )
        ],
      ),
      // 5. Wrap in RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async => _loadDrills(),
        // 6. Use FutureBuilder instead of StreamBuilder
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _drillsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final drills = snapshot.data ?? [];

            if (drills.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_call_outlined,
                          size: 60,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      const Text('No custom drills found.'),
                      Text(
                        'Go back and create one first!',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 7. We have drills! Build the list.
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: drills.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final drillData = drills[index];
                // Note: drillData already contains 'id' from the repository mapping

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
                      _assignDrill(drillData);
                    },
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