import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to show a confirmation dialog for logout
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // Implement Logout logic here
                Navigator.of(ctx).pop(); // Close the dialog
                // Navigate all the way back to the login screen, clearing the history
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // --- Account Section ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  title: 'Edit User Name',
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text('Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  icon: Icons.family_restroom,
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