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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Display Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter new name",
              labelText: "Name",
              border: OutlineInputBorder(),
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
                final success = await _viewModel.updateName(
                    athleteId, nameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Name updated successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(_viewModel.errorMessage ?? 'Error'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                final success =
                    await _viewModel.updatePin(athleteId, pinController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('PIN updated successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(_viewModel.errorMessage ?? 'Error'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _viewModel.logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // DARK BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF121212),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildSectionTitle('Profile', theme),
              _buildSectionCard(
                children: [
                  _buildSettingsTile(
                    context: context,
                    title: 'Change Display Name',
                    icon: Icons.person_outline,
                    onTap: _showChangeNameDialog,
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    context: context,
                    title: 'Change Login PIN',
                    icon: Icons.lock_outline,
                    onTap: _showChangePinDialog,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Preferences', theme),
              _buildSectionCard(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.volume_up,
                          color: theme.primaryColor, size: 20),
                    ),
                    title: const Text('App Sounds',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                    value: _appSounds,
                    activeColor: theme.primaryColor,
                    onChanged: (bool value) {
                      setState(() {
                        _appSounds = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.notifications_active,
                          color: theme.primaryColor, size: 20),
                    ),
                    title: const Text('Push Notifications',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                    value: _pushNotifications,
                    activeColor: theme.primaryColor,
                    onChanged: (bool value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('App Info', theme),
              _buildSectionCard(
                children: [
                  _buildSettingsTile(
                    context: context,
                    title: 'Help & Support',
                    icon: Icons.support_agent,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    context: context,
                    title: 'About CoachFitness',
                    icon: Icons.info_outline,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showLogoutConfirmDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade700),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      trailing: Icon(Icons.chevron_right,
          color: Colors.grey.shade600, size: 20),
      onTap: onTap,
    );
  }
}