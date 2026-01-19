import 'package:flutter/material.dart';
import '../viewmodel/training_viewmodel.dart';
// Import Drill Detail for navigation
import 'drill_detail_view.dart';

class TrainingView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  final bool embedded; // When true, no Scaffold wrapper (used in shell)

  const TrainingView({super.key, required this.athleteData, this.embedded = false});

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
    _loadDrills();
  }

  void _loadDrills() {
    setState(() {
      // Only load if we have a coach, otherwise return empty list
      if (_viewModel.hasCoach) {
        _drillsFuture = _viewModel.fetchCoachDrills();
      } else {
        _drillsFuture = Future.value([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Training Center",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.embedded,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_viewModel.hasCoach)
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
              onPressed: _loadDrills,
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
          child: _viewModel.hasCoach ? _buildDrillsList() : _buildNoCoachView(),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // SCENARIO 1: NO COACH LINKED -> SHOW INSTRUCTIONS
  // -------------------------------------------------------
  Widget _buildNoCoachView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child:
                  Icon(Icons.link_off, size: 60, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 30),
            const Text(
              "No Coach Connected",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You need a coach to assign you drills before you can train here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 40),

            // Instruction Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text(
                        "How to connect",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BCD4),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Share your Connection Code (found on your Dashboard) with your coach.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00BCD4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Back to Dashboard", style: TextStyle(color: Color(0xFF00BCD4))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // SCENARIO 2: COACH LINKED -> SHOW DRILLS
  // -------------------------------------------------------
  Widget _buildDrillsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _drillsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }

        final drills = snapshot.data ?? [];

        if (drills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_outlined,
                    size: 60, color: const Color(0xFF00BCD4).withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  "Your coach hasn't created any drills yet.",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadDrills(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: drills.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final drill = drills[index];
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Navigate to detail (reuse existing Drill Detail logic)
                      Navigator.pushNamed(
                        context,
                        '/drill-detail',
                        arguments: {
                          'athleteId': widget.athleteData['id'],
                          'drillData': {
                            ...drill,
                            'coachUid': widget.athleteData[
                                'coachUid'], // Pass coach ID for upload
                          },
                        },
                      );
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Color(0xFF00BCD4), size: 28),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drill['name'] ?? 'Untitled Drill',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.category,
                                        size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${drill['skillFocus']}",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.bolt,
                                        size: 14, color: Colors.orange.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${drill['xp']} XP",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Arrow
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}