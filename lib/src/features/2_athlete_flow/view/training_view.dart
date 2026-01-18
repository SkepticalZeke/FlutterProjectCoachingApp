import 'package:flutter/material.dart';
import '../viewmodel/training_viewmodel.dart';
// Import Drill Detail for navigation
import 'drill_detail_view.dart'; 

class TrainingView extends StatefulWidget {
  final Map<String, dynamic> athleteData;

  const TrainingView({super.key, required this.athleteData});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  final _viewModel = TrainingViewModel();
  late Future<List<Map<String, dynamic>>> _drillsFuture;

  @override
  void initState() {
    super.initState();
    _viewModel.initialize(widget.athleteData);
    
    // Only load if we have a coach, otherwise return empty list
    if (_viewModel.hasCoach) {
      _drillsFuture = _viewModel.fetchCoachDrills();
    } else {
      _drillsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------
    // SCENARIO 1: NO COACH LINKED -> SHOW INSTRUCTIONS
    // -------------------------------------------------------
    if (!_viewModel.hasCoach) {
      return Scaffold(
        appBar: AppBar(title: const Text("Training Center")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                const Text(
                  "No Coach Connected",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "You need a coach to assign you drills before you can train here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                
                // Instruction Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "How to connect:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Share your Connection Code (found on your Dashboard) with your coach.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Dashboard"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------
    // SCENARIO 2: COACH LINKED -> SHOW DRILLS
    // -------------------------------------------------------
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coach's Drills"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _drillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final drills = snapshot.data ?? [];

          if (drills.isEmpty) {
            return const Center(
              child: Text("Your coach hasn't created any drills yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drills.length,
            itemBuilder: (context, index) {
              final drill = drills[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.blue),
                  ),
                  title: Text(
                    drill['name'] ?? 'Untitled Drill',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "${drill['skillFocus']} • ${drill['xp']} XP"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to detail (reuse existing Drill Detail logic)
                    // We construct a mock "drillData" object for the detail view
                    Navigator.pushNamed(
                      context, 
                      '/drill-detail',
                      arguments: {
                        'athleteId': widget.athleteData['id'],
                        'drillData': {
                          ...drill,
                          'coachUid': widget.athleteData['coachUid'], // Pass coach ID for upload
                        },
                      }
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