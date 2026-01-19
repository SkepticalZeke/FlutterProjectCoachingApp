import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
import '../viewmodel/rewards_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class RewardsView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  final bool embedded; // When true, no Scaffold wrapper (used in shell)
  const RewardsView({super.key, required this.athleteData, this.embedded = false});

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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Trophy Cabinet',
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
                  child:
                      const Icon(Icons.refresh, size: 20, color: Colors.amber),
                ),
                onPressed: _loadData,
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
              child: Column(
                children: [
                  // --- 1. Player Level & XP Summary ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10.0),
                    child: _buildPlayerSummary(context, liveData),
                  ),

                  // --- 2. Achievements Grid ---
                  Expanded(
                    // Wrap Grid in RefreshIndicator for Pull-to-Refresh
                    child: RefreshIndicator(
                      onRefresh: () async => _loadData(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24.0),
                        // AlwaysScrollable ensures refresh works even if items don't fill screen
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
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
            ),
          ),
        );
      },
    );
  }

  // 2. Updated to accept Map data directly (No StreamBuilder)
  Widget _buildPlayerSummary(
      BuildContext context, Map<String, dynamic> data) {
    int currentLevel = data['level'] ?? 1;
    int totalXp = (data['totalXp'] ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.amber.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Level',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Container(
            height: 50,
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Lifetime XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$totalXp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF1E1E1E) : const Color(0xFF1E1E1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        border: Border.all(
          color: isUnlocked ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? color.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              isUnlocked ? icon : Icons.lock,
              size: 32,
              color: isUnlocked ? color : Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: isUnlocked
                    ? Colors.white
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}