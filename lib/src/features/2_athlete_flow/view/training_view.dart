import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/training_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class TrainingView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const TrainingView({super.key, required this.athleteData});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  final _viewModel = TrainingViewModel();
  
  // State for API Data
  late Future<List<Map<String, dynamic>>> _drillsFuture;

  @override
  void initState() {
    super.initState();
    _viewModel.initialize(widget.athleteData);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _drillsFuture = _viewModel.fetchCoachDrills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      // 1. Wrap in RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        // 2. Use FutureBuilder
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _drillsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // 3. Process Custom Drills (from API)
            List<Map<String, dynamic>> customDrills = [];
            if (snapshot.hasData) {
              customDrills = snapshot.data!.map((data) {
                // Add/format data to match the UI's needs
                return {
                  'name': data['name'] ?? 'Unnamed Drill',
                  'goal': data['goal'] ?? '',
                  'category': 'Coach Drill (${data['skillFocus'] ?? 'General'})',
                  'iconData': 0xe722, // video_library
                  'color': theme.colorScheme.primary,
                  'xp': data['xp'] ?? 50,
                  'time': data['time'] ?? 120,
                  'videoUrl': data['videoUrl'] ?? '',
                  'id': data['id'], // Keep ID for reference
                };
              }).toList();
            }

            // 4. Combine default drills and custom drills
            final allDrills = [
              ...customDrills,
              ..._viewModel.defaultDrills
            ];

            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              // AlwaysScrollable ensures Pull-to-Refresh works even if list is short
              physics: const AlwaysScrollableScrollPhysics(),
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
                      // Navigate to detail (Preview Mode)
                      final routeArgs = {
                        'athleteId': widget.athleteData['id'],
                        'drillId': drill['id'] ?? 'default_$index',
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
      ),
    );
  }
}