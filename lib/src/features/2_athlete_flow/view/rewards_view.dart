import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
import '../viewmodel/rewards_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class RewardsView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const RewardsView({super.key, required this.athleteData});

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  final _viewModel = RewardsViewModel();
  
  // State for API Data
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _viewModel.initialize(widget.athleteData);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _profileFuture = _viewModel.fetchAthleteProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the whole screen in FutureBuilder so we have the latest XP/Level data
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // Use latest data or fallback to widget arguments
        final liveData = snapshot.data ?? widget.athleteData;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Trophy Cabinet'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              )
            ],
          ),
          body: Column(
            children: [
              // --- 1. Player Level & XP Summary ---
              // Pass the data directly instead of building a stream inside
              _buildPlayerSummary(context, liveData),

              // --- 2. Achievements Grid ---
              Expanded(
                // Wrap Grid in RefreshIndicator for Pull-to-Refresh
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20.0),
                    // AlwaysScrollable ensures refresh works even if items don't fill screen
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _viewModel.achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = _viewModel.achievements[index];
                      // Note: In a real app, you would check liveData['achievements'] here
                      // to see if this specific achievement is unlocked.
                      // For now, using the static 'unlocked' property from VM.
                      
                      return AchievementBadge(
                        name: achievement['name'] as String,
                        icon: achievement['icon'] as IconData,
                        color: achievement['color'] as Color,
                        isUnlocked: achievement['unlocked'] as bool,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Updated to accept Map data directly (No StreamBuilder)
  Widget _buildPlayerSummary(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);

    int currentLevel = data['level'] ?? 1;
    int totalXp = (data['totalXp'] ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity, // Center horizontally
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                'Current Level: $currentLevel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total XP Earned: $totalXp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- AchievementBadge widget (Unchanged) ---
class AchievementBadge extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.7) : Colors.grey[800]!,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 44,
              color: isUnlocked ? color : Colors.grey[600],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}