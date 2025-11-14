import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to show a confirmation dialog for logout
  void _showLogoutConfirmDialog(BuildContext context) {
    // 1. UI Theme: Get theme from context
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          // 2. UI Theme: Apply theme colors to dialog
          backgroundColor: theme.colorScheme.surface,
          title: Text('Confirm Logout',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to log out?',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              child: const Text('Cancel'), // Will use theme's default color
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              // 3. UI Theme: Semantic color (red) is good, keep it
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
                // This navigation is correct for the athlete
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Helper function for building a list tile
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    // 4. UI Theme: Get theme from context
    final theme = Theme.of(context);
    return ListTile(
      // 5. UI Theme: Icon already uses primary color (cyan), which is perfect
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      // 6. UI Theme: Update trailing icon color
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 7. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // 8. UI Theme: Removed colors, uses main.dart theme
      ),
      body: ListView(
        children: [
          // --- Account Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            // 9. UI Theme: Use primary cyan for section headers
            child: Text('Account',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ),
          Card(
            // 10. UI Theme: Card style comes from main.dart
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  // 11. Text refactored: 'User' -> 'Athlete'
                  title: 'Edit Athlete Name',
                  icon: Icons.person,
                  onTap: () {
                    // Placeholder: Show dialog to edit name
                  },
                ),
                const Divider(height: 1, indent: 16),
                _buildSettingsTile(
                  context: context,
                  title: 'Change 4-Digit PIN',
                  icon: Icons.lock_outline,
                  onTap: () {
                    // Placeholder: Show dialog to change PIN
                  },
                ),
              ],
            ),
          ),

          // --- Preferences Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            // 12. UI Theme: Use primary cyan for section headers
            child: Text('Preferences',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  title: 'App Sounds',
                  icon: Icons.volume_up,
                  trailing: Switch(
                    value: true, // Mock value
                    // 13. UI Theme: Switch will use primary color
                    onChanged: (bool val) {
                      // Placeholder: Update sound preference
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16),
                _buildSettingsTile(
                  context: context,
                  title: 'Push Notifications',
                  icon: Icons.notifications,
                  trailing: Switch(
                    value: true, // Mock value
                    onChanged: (bool val) {
                      // Placeholder: Update notification preference
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- Support Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            // 14. UI Theme: Use primary cyan for section headers
            child: Text('Support',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  title: 'Help Center',
                  icon: Icons.help_outline,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16),
                _buildSettingsTile(
                  context: context,
                  title: 'Contact CoachFitness Support',
                  // 15. Icon refactored: 'family' -> 'support'
                  icon: Icons.support_agent,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // --- Logout Button ---
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ElevatedButton(
              onPressed: () {
                _showLogoutConfirmDialog(context);
              },
              // 16. UI Theme: Semantic color (red) is good, keep it
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}