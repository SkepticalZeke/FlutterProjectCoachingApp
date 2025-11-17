import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new ViewModel
import '../viewmodel/training_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class TrainingView extends StatefulWidget {
  // 1. CONSTRUCTOR UPDATED
  final Map<String, dynamic> athleteData;
  const TrainingView({super.key, required this.athleteData});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  // 2. The View owns its ViewModel
  final _viewModel = TrainingViewModel();

  @override
  void initState() {
    super.initState();
    // 3. Initialize the ViewModel
    _viewModel.initialize(widget.athleteData);
  }

  // 4. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drills'),
      ),
      // 5. Listen to the stream from the ViewModel
      body: StreamBuilder<QuerySnapshot>(
        stream: _viewModel.coachDrillsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 6. Get the coach's custom drills
          List<Map<String, dynamic>> customDrills = [];
          if (snapshot.hasData) {
            customDrills = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Add/format data to match the UI's needs
              return {
                'name': data['name'] ?? 'Unnamed Drill',
                'goal': data['goal'] ?? '',
                'category': 'Coach Drill (${data['skillFocus']})',
                'iconData': 0xe722, // video_library
                'color': theme.colorScheme.primary,
                'xp': data['xp'] ?? 50,
                'time': data['time'] ?? 120,
                'videoUrl': data['videoUrl'] ?? '',
              };
            }).toList();
          }

          // 7. Combine default drills and custom drills
          final allDrills = [
            ...customDrills,
            ..._viewModel.defaultDrills
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: allDrills.length,
            itemBuilder: (context, index) {
              final drill = allDrills[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Icon(
                    IconData(drill['iconData'] as int,
                        fontFamily: 'MaterialIcons'),
                    color: drill['color'] as Color,
                    size: 40,
                  ),
                  title: Text(
                    drill['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(drill['category'] as String),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Note: This navigates to the drill detail, but
                    // we haven't built the logic to "assign" it.
                    // This just shows the detail page.
                    final routeArgs = {
                      'athleteId': widget.athleteData['id'],
                      'drillId': 'mock_id', // This is just a preview
                      'drillData': drill,
                    };
                    Navigator.of(context).pushNamed(
                      '/drill-detail',
                      arguments: routeArgs,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}