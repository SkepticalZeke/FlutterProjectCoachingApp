import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
import '../viewmodel/rewards_viewmodel.dart';

/*
  VIEW (V)
  Refactored RewardsView with:
  - Premium "Trophy Room" Aesthetic
  - Gradient Background
  - Glass-style Stats Card
  - Enhanced Achievement Badges
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Wrap the whole screen in FutureBuilder
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // Use latest data or fallback to widget arguments
        final liveData = snapshot.data ?? widget.athleteData;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Trophy Cabinet',
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
                ),
              )
            ],
          ),
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
              child: Column(
                children: [
                  // --- 1. Player Level & XP Summary ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: _buildPlayerSummary(context, liveData),
                  ),

                  // --- 2. Achievements Grid ---
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, 
                                     color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Badges Collected',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async => _loadData(),
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.8,
                                ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Updated to accept Map data directly
  Widget _buildPlayerSummary(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int currentLevel = data['level'] ?? 1;
    int totalXp = (data['totalXp'] ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level $currentLevel',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.auto_graph_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$totalXp Lifetime XP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- AchievementBadge widget ---
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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked 
            ? colorScheme.surface 
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isUnlocked ? color : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: isUnlocked ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ),
          if (!isUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Icon(Icons.lock_rounded, size: 14, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }
}