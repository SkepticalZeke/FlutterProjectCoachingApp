import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new ViewModel
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
  // 1. The View owns its ViewModel
  final _viewModel = RewardsViewModel();

  @override
  void initState() {
    super.initState();
    // 2. Initialize the ViewModel
    _viewModel.initialize(widget.athleteData);
    // We don't need to listen, as StreamBuilders will update the UI
  }

  // 3. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trophy Cabinet'),
      ),
      body: Column(
        children: [
          // --- 1. Player Level & XP Summary (Live) ---
          _buildPlayerSummary(context),

          // --- 2. Achievements Grid (from ViewModel) ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              // 4. Get list from ViewModel
              itemCount: _viewModel.achievements.length,
              itemBuilder: (context, index) {
                final achievement = _viewModel.achievements[index];
                return AchievementBadge(
                  name: achievement['name'] as String,
                  icon: achievement['icon'] as IconData,
                  color: achievement['color'] as Color,
                  isUnlocked: achievement['unlocked'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 5. This helper is now a StreamBuilder listening to the ViewModel
  Widget _buildPlayerSummary(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: _viewModel.athleteStream,
      builder: (context, snapshot) {
        // Default values
        int currentLevel = 1;
        int totalXp = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentLevel = data['level'] ?? 1;
          totalXp = (data['totalXp'] ?? 0).toInt();
        }

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Current Level: $currentLevel', // ⭐️ Use real data
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total XP Earned: $totalXp', // ⭐️ Use real data
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- AchievementBadge widget (Unchanged) ---
// (We should move this to lib/src/shared/widgets/ later)
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
          color: isUnlocked ? color.withOpacity(0.7) : Colors.grey[800]!,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
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