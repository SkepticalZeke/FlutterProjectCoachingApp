import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/settings_viewmodel.dart';
// Note: No Firebase imports here!
class SettingsView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const SettingsView({super.key, required this.athleteData});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _viewModel = SettingsViewModel();

  // Local state for UI preferences (Restore these)
  bool _appSounds = true;
  bool _pushNotifications = true;

  // Helper to get the ID safely
  String get athleteId => widget.athleteData['id'];

  // --- UI: Show Dialog to Change Name ---
  void _showChangeNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = widget.athleteData['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Display Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter new name",
              labelText: "Name",
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _viewModel.updateName(athleteId, nameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name updated successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_viewModel.errorMessage ?? 'Error')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- UI: Show Dialog to Change PIN ---
  void _showChangePinDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Login PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter a new 4-digit PIN for logging in."),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: "0000",
                  labelText: "New PIN",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _viewModel.updatePin(athleteId, pinController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN updated successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_viewModel.errorMessage ?? 'Error')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _viewModel.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Profile',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 1. Change Name
          _buildSettingsTile(
            context: context,
            title: 'Change Display Name',
            icon: Icons.person_outline,
            onTap: _showChangeNameDialog,
          ),

          // 2. Change PIN
          _buildSettingsTile(
            context: context,
            title: 'Change Login PIN',
            icon: Icons.lock_outline,
            onTap: _showChangePinDialog,
          ),

          const Divider(),

          // --- RESTORED: App Preferences Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              'Preferences',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 3. App Sounds Toggle
          SwitchListTile(
            secondary: Icon(Icons.volume_up, color: theme.colorScheme.primary),
            title: const Text('App Sounds', style: TextStyle(fontWeight: FontWeight.w500)),
            value: _appSounds,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (bool value) {
              setState(() {
                _appSounds = value;
              });
              // TODO: Save preference to SharedPreferences or Database
            },
          ),

          // 4. Push Notifications Toggle
          SwitchListTile(
            secondary: Icon(Icons.notifications_active, color: theme.colorScheme.primary),
            title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
            value: _pushNotifications,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
              });
              // TODO: Save preference to SharedPreferences or Database
            },
          ),

          const Divider(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Text(
              'App Info',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
           _buildSettingsTile(
            context: context,
            title: 'Help & Support',
            icon: Icons.support_agent,
            onTap: () {},
          ),

          const SizedBox(height: 40),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ElevatedButton(
              onPressed: () => _showLogoutConfirmDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}