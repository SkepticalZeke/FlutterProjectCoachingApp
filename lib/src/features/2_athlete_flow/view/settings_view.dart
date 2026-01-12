import 'package:flutter/material.dart';
// Import the new ViewModel
import '../viewmodel/settings_viewmodel.dart';
// Note: No Firebase imports here!

/*
  VIEW (V)
  Refactored SettingsView with:
  - Gradient Background
  - Sectioned "Card" Layout
  - Modern Switch Styling
  - Polished Dialogs & Buttons
*/
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Display Name', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Enter new name",
              labelText: "Name",
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final success = await _viewModel.updateName(athleteId, nameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Name updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_viewModel.errorMessage ?? 'Error'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Login PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter a new 4-digit PIN for logging in.", 
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 5),
                decoration: InputDecoration(
                  hintText: "0000",
                  labelText: "New PIN",
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  counterText: "",
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
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final success = await _viewModel.updatePin(athleteId, pinController.text);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('PIN updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_viewModel.errorMessage ?? 'Error'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _viewModel.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Profile Section
              _buildSectionHeader(context, 'Account'),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context: context,
                      title: 'Display Name',
                      subtitle: widget.athleteData['name'] ?? 'Not set',
                      icon: Icons.person_rounded,
                      iconColor: Colors.blueAccent,
                      onTap: _showChangeNameDialog,
                    ),
                    Divider(height: 1, indent: 60, color: colorScheme.outlineVariant.withOpacity(0.5)),
                    _buildSettingsTile(
                      context: context,
                      title: 'Security PIN',
                      subtitle: 'Change your login PIN',
                      icon: Icons.lock_rounded,
                      iconColor: Colors.amber[700]!,
                      onTap: _showChangePinDialog,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // 2. Preferences Section
              _buildSectionHeader(context, 'Preferences'),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context, 
                      'App Sounds', 
                      _appSounds, 
                      Icons.volume_up_rounded,
                      Colors.teal,
                      (val) => setState(() => _appSounds = val),
                    ),
                    Divider(height: 1, indent: 60, color: colorScheme.outlineVariant.withOpacity(0.5)),
                    _buildSwitchTile(
                      context, 
                      'Notifications', 
                      _pushNotifications, 
                      Icons.notifications_active_rounded,
                      Colors.purple,
                      (val) => setState(() => _pushNotifications = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // 3. System / App Info
              _buildSectionHeader(context, 'System'),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context: context,
                      title: 'Help & Support',
                      icon: Icons.support_agent_rounded,
                      iconColor: Colors.indigo,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Contact support@coachfitness.com")),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 60, color: colorScheme.outlineVariant.withOpacity(0.5)),
                    _buildSettingsTile(
                      context: context,
                      title: 'About App',
                      subtitle: 'Version 1.0.0',
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.grey,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, 
    String title, 
    bool value, 
    IconData icon, 
    Color iconColor,
    ValueChanged<bool> onChanged
  ) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      activeColor: theme.colorScheme.primary,
      onChanged: onChanged,
    );
  }
}