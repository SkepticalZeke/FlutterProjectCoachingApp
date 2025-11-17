import 'package:flutter/material.dart';

class SkillProgressBar extends StatelessWidget {
  final double currentXp;
  final double requiredXp;
  final int level;

  const SkillProgressBar({
    super.key,
    required this.currentXp,
    required this.requiredXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXp / requiredXp;
    // 1. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 2. UI Theme: Use theme surface color instead of Colors.white
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        // 3. UI Theme: Removed shadow, as it's not visible on dark theme
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // 4. Text Refactor: Generalized "Rookie Star"
                'Level $level: Rising Star',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // 5. UI Theme: This will now correctly use the (cyan) primary color
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'XP: ${currentXp.toInt()}/${requiredXp.toInt()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  // 6. UI Theme: Use a light, secondary text color
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              // 7. UI Theme: Use a subtle background for the bar
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              // 8. UI Theme: Kept Amber for XP, it's a great accent color
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 8),

          // Unlock message
          Text(
            // 9. Text Refactor: Changed "new Kit" to "next Level"
            '${(requiredXp - currentXp).toInt()} XP until the next Level!',
            style: TextStyle(
              fontSize: 14,
              // 10. UI Theme: Use a light, secondary text color
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}