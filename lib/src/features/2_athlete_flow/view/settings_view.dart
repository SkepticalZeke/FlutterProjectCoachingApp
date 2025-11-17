import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/settings_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
*/
class SettingsView extends StatefulWidget {
  // 1. CONSTRUCTOR UPDATED
  final Map<String, dynamic> athleteData;
  const SettingsView({super.key, required this.athleteData});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // 2. The View owns its ViewModel
  final _viewModel = SettingsViewModel();

  // 3. "handle" function now calls the ViewModel
  void _showLogoutConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Confirm Logout',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to log out?',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // 4. CALL THE VIEWMODEL TO LOG OUT
                await _viewModel.logout();

                if (context.mounted) {
                  Navigator.of(ctx).pop(); // Close the dialog
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // 5. Build method is "dumb"
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // --- Account Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text('Account',
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

  // Helper widget is just UI, so it stays in the View
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}