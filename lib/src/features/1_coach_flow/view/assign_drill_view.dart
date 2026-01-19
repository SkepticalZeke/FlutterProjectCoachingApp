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
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Assign Drill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
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
                  ]),
              child: const Icon(Icons.refresh, size: 20, color: Color(0xFF00BCD4)),
            ),
            onPressed: _loadDrills,
          )
        ],
      ),
      // 5. Wrap in RefreshIndicator
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            children: [
              // Info Banner
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1,
                        color: Color(0xFF00BCD4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Assigning to: ",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      widget.athleteData['name'] ?? "Athlete",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    )
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
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
                                Icon(Icons.video_library_outlined,
                                    size: 80,
                                    color: const Color(0xFF00BCD4).withOpacity(0.3)),
                                const SizedBox(height: 20),
                                Text(
                                  'No drills found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[300]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a drill in your dashboard first!',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // 7. We have drills! Build the list.
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: drills.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final drillData = drills[index];
                          // Note: drillData already contains 'id' from the repository mapping

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  _assignDrill(drillData);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Icon Container
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.play_circle_fill,
                                            color: Color(0xFF00BCD4),
                                            size: 28),
                                      ),
                                      const SizedBox(width: 16),

                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              drillData['name'] ??
                                                  'Unnamed Drill',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.bolt,
                                                    size: 14,
                                                    color: Colors.orange[400]),
                                                Text(
                                                  ' ${drillData['xp']} XP',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.category,
                                                    size: 14,
                                                    color: Colors.purple[300]),
                                                Text(
                                                  ' ${drillData['skillFocus']}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Assign Action Button
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.green.shade700),
                                        ),
                                        child: const Text(
                                          "Assign",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}