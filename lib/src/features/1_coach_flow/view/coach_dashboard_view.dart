import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/coach_dashboard_viewmodel.dart';

/*
  VIEW (V)
  Refactored CoachDashboardView with:
  - Modern Dashboard Layout
  - Gradient Backgrounds
  - Elevated Cards with Shadows
  - Improved Typography & Iconography
*/
class CoachDashboardView extends StatefulWidget {
  const CoachDashboardView({super.key});

  @override
  State<CoachDashboardView> createState() => _CoachDashboardViewState();
}

class _CoachDashboardViewState extends State<CoachDashboardView> {
  // 1. The View owns its ViewModel
  final _viewModel = CoachDashboardViewModel();
  
  // 2. State for API Data
  late Future<List<Map<String, dynamic>>> _athletesFuture;

  @override
  void initState() {
    super.initState();
    // Load initial data
    _loadAthletes();
  }

  void _loadAthletes() {
    setState(() {
      _athletesFuture = _viewModel.fetchAthletes();
    });
  }

  // 3. The View handles the logout logic
  void _handleLogout() async {
    await _viewModel.logout();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/role-selection', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Handle case where user isn't logged in
    if (_viewModel.coachUid == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.surface, colorScheme.errorContainer.withOpacity(0.2)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 20),
                Text('Session Expired', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.login),
                  label: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Coach Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed('/coach-notifications');
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      // 4. Wrap body in Container for Gradient Background
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
        child: RefreshIndicator(
          onRefresh: () async => _loadAthletes(),
          // 5. Use FutureBuilder
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _athletesFuture,
            builder: (context, snapshot) {
              // Handle Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Handle Error State
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading dashboard: ${snapshot.error}'),
                      TextButton(onPressed: _loadAthletes, child: const Text("Retry"))
                    ],
                  ),
                );
              }
              
              final athletes = snapshot.data ?? [];

              // Handle No Data State
              if (athletes.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.people_outline,
                                size: 80,
                                color: colorScheme.onSurface.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No athletes yet',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Actions" to add your first athlete.',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Build the UI with the real data
              return SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // Extra padding for FAB
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Here is your team\'s progress.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Pass the real athlete list to the overview card
                      _buildOverviewCard(context, athletes),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Athletes',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${athletes.length} Active',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Map the real documents to the tile widget
                      ...athletes.map((athleteData) => _buildAthleteTile(context, athleteData)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        backgroundColor: colorScheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 6. Modern Overview Card
  Widget _buildOverviewCard(
      BuildContext context, List<Map<String, dynamic>> athletes) {
    
    final completedCount = athletes.where((data) {
      return (data['progress'] ?? 0.0) == 1.0;
    }).length;
    
    final totalCount = athletes.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate percentage
    final double percent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Completion',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$completedCount',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 36, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        '/ $totalCount Athletes',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Circular progress indicator
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${(percent * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Athlete Tile
  Widget _buildAthleteTile(
      BuildContext context, Map<String, dynamic> athleteData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isComplete = (athleteData['progress'] ?? 0.0) == 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // Navigate and wait for return to refresh data
            await Navigator.of(context).pushNamed(
              '/coach-athlete-detail',
              arguments: athleteData,
            );
            _loadAthletes();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green.withOpacity(0.1) : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: isComplete ? Border.all(color: Colors.green.withOpacity(0.5), width: 2) : null,
                  ),
                  child: Center(
                    child: Icon(
                      isComplete ? Icons.check_rounded : Icons.person_rounded,
                      color: isComplete ? Colors.green : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athleteData['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                           // Level Badge
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Lvl ${athleteData['level'] ?? 1}',
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: colorScheme.primary
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Streak
                          Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                          Text(
                            ' ${athleteData['streak'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12, 
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      athleteData['status'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? Colors.green[700] : colorScheme.error,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for custom styling
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildActionTile(
                  context,
                  icon: Icons.video_library_rounded,
                  color: Colors.blueAccent,
                  title: 'Create New Drill',
                  subtitle: 'Upload video & set XP',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed('/create-drill');
                  },
                ),
                
                _buildActionTile(
                  context,
                  icon: Icons.person_add_rounded,
                  color: Colors.green,
                  title: 'Add New Athlete',
                  subtitle: 'Create profile for new player',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddAthleteDialog();
                  },
                ),

                _buildActionTile(
                  context,
                  icon: Icons.playlist_add_check_rounded,
                  color: Colors.orange,
                  title: 'Mass Assign Drill',
                  subtitle: 'Assign to multiple athletes',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mass Assign Coming Soon!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required IconData icon, 
    required Color color, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  void _showAddAthleteDialog() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Athlete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Athlete Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: '4-Digit PIN',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                counterText: "", // Hide counter
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  pinController.text.length == 4) {
                Navigator.pop(ctx); // Close dialog
                
                // Call ViewModel
                final success = await _viewModel.addNewAthlete(
                  nameController.text.trim(),
                  pinController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(success ? 'Athlete added!' : 'Failed to add athlete.'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: success ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  if (success) {
                    _loadAthletes(); // Refresh list immediately
                  }
                }
              }
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}