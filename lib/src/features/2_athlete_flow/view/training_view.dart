import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/training_viewmodel.dart';

/*
  VIEW (V)
  Refactored TrainingView with:
  - Gradient Background
  - Modern "Workout Card" UI
  - Visual Tags for Time & XP
  - Highlighted "Coach Assigned" Drills
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Training Library',
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
              onPressed: _loadData,
              tooltip: "Refresh Library",
            ),
          )
        ],
      ),
      // 1. Wrap in Gradient Container
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
            onRefresh: () async => _loadData(),
            // 2. Use FutureBuilder
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _drillsFuture,
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
                      ],
                    ),
                  );
                }

                // 3. Process Custom Drills (from API)
                List<Map<String, dynamic>> customDrills = [];
                if (snapshot.hasData) {
                  customDrills = snapshot.data!.map((data) {
                    return {
                      'name': data['name'] ?? 'Unnamed Drill',
                      'goal': data['goal'] ?? '',
                      'category': 'Coach Assigned',
                      'skillFocus': data['skillFocus'] ?? 'General',
                      'iconData': 0xe722, // video_library rounded
                      'color': Colors.orange, // Highlight custom drills
                      'xp': data['xp'] ?? 50,
                      'time': data['time'] ?? 120,
                      'videoUrl': data['videoUrl'] ?? '',
                      'id': data['id'],
                      'isCustom': true,
                    };
                  }).toList();
                }

                // 4. Combine with Default Drills
                final defaultDrills = _viewModel.defaultDrills.map((d) => {
                  ...d,
                  'isCustom': false,
                  // Ensure color is mapped properly
                  'color': d['color'] is Color ? d['color'] : colorScheme.primary, 
                }).toList();

                final allDrills = [
                  ...customDrills,
                  ...defaultDrills
                ];

                if (allDrills.isEmpty) {
                   return const Center(child: Text("No drills available."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: allDrills.length,
                  itemBuilder: (context, index) {
                    final drill = allDrills[index];
                    return _buildDrillCard(context, drill);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrillCard(BuildContext context, Map<String, dynamic> drill) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isCustom = drill['isCustom'] == true;
    
    // Custom styling for coach drills
    final Color accentColor = drill['color'] as Color? ?? colorScheme.primary;
    final Color cardBg = isCustom 
        ? Colors.orange.withOpacity(0.05) 
        : colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCustom ? Colors.orange.withOpacity(0.3) : colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to detail
            final routeArgs = {
              'athleteId': widget.athleteData['id'],
              'drillId': drill['id'] ?? 'default_${drill['name']}',
              'drillData': drill,
            };
            Navigator.of(context).pushNamed(
              '/drill-detail',
              arguments: routeArgs,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    IconData(drill['iconData'] as int, fontFamily: 'MaterialIcons'),
                    color: accentColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              drill['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCustom)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'COACH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        drill['category'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Stats Row
                      Row(
                        children: [
                          _buildInfoTag(
                            context, 
                            Icons.timer_outlined, 
                            "${(drill['time'] as int) ~/ 60}m",
                            colorScheme.secondary
                          ),
                          const SizedBox(width: 8),
                          _buildInfoTag(
                            context, 
                            Icons.star_rounded, 
                            "${drill['xp']} XP",
                            Colors.amber[800]!
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}