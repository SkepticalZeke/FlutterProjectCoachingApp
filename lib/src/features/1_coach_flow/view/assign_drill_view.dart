import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/assign_drill_viewmodel.dart';

/*
  VIEW (V)
  Refactored AssignDrillView with:
  - Custom Card UI with Gradients
  - "Chip" style tags for Skills and XP
  - Modern background styling
  - Enhanced visual feedback
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
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Assigned "${drillData['name']}" to ${widget.athleteData['name']}!'
                      : 'Error assigning drill.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (success) {
        Navigator.of(context).pop(); // Go back to the detail screen on success
      }
    }
  }

  // 4. Build method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows gradient to go behind AppBar
      appBar: AppBar(
        title: Text(
          'Assign to ${widget.athleteData['name']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Transparent for gradient effect
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.9),
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
              icon: const Icon(Icons.refresh),
              onPressed: _loadDrills,
              tooltip: "Refresh Drills",
            ),
          )
        ],
      ),
      // 5. Wrap in Container for Background Gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.08) ?? Colors.grey[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadDrills(),
            // 6. Use FutureBuilder
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
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Something went wrong loading drills.', style: theme.textTheme.bodyLarge),
                        TextButton(onPressed: _loadDrills, child: const Text("Try Again"))
                      ],
                    ),
                  );
                }

                final drills = snapshot.data ?? [];

                if (drills.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.video_call_outlined,
                                size: 64,
                                color: colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Custom Drills Found',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Go back and create one first!',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 7. We have drills! Build the modern list.
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: drills.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final drillData = drills[index];
                    return _buildDrillCard(context, drillData, theme, colorScheme);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the modern card
  Widget _buildDrillCard(BuildContext context, Map<String, dynamic> drillData, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _assignDrill(drillData),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drillData['name'] ?? 'Unnamed Drill',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chips Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(
                            theme, 
                            drillData['skillFocus'] ?? 'General', 
                            Icons.bolt,
                            Colors.orange,
                          ),
                          _buildInfoChip(
                            theme, 
                            "${drillData['xp'] ?? 0} XP", 
                            Icons.star_rounded,
                            Colors.amber,
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
                    color: colorScheme.secondaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}