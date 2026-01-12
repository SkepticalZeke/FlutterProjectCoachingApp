import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/avatar_viewmodel.dart';

/*
  VIEW (V)
  Refactored AvatarView with:
  - Gradient Background & Spotlight Effect
  - Modern "Glass" Currency Chips
  - Polished Inventory Grid
  - Enhanced Tab Styling
*/
class AvatarView extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const AvatarView({super.key, required this.athleteData});

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView>
    with SingleTickerProviderStateMixin {
  // 1. The View owns its ViewModel
  final _viewModel = AvatarViewModel();
  late TabController _tabController;
  
  // 2. State for our API Data
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Initialize ViewModel
    _viewModel.initialize(widget.athleteData);
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen for changes (error messages)
    _viewModel.addListener(_onViewModelChanged);
    
    // Load Initial Data
    _loadProfile();
  }

  // Helper to fetch data from API
  Future<void> _loadProfile() async {
    setState(() {
      _profileFuture = _viewModel.fetchAthleteProfile();
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.errorMessage != null) {
      _showErrorSnackBar(_viewModel.errorMessage!);
    }
    setState(() {}); // Rebuild to update loading spinner if needed
  }

  // 3. Handle Item Selection (Buy or Equip)
  void _handleItemSelect(
    Map<String, dynamic> item,
    String category,
    Map<String, dynamic> liveAthleteData,
  ) async {
    final result = await _viewModel.purchaseOrEquipItem(
      item,
      liveAthleteData,
    );
    
    if (mounted) {
      // Don't show snackbar for simple equips to keep UI snappy, unless error
      if (_viewModel.errorMessage != null || result.contains("purchase")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                _viewModel.errorMessage == null ? Colors.green : Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      // 4. IMPORTANT: Refresh the profile to show new Stars balance / Equipped item
      _loadProfile();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 5. FutureBuilder replaces StreamBuilder
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // Use latest fetched data, or fallback to the data passed in navigation
        final liveAthleteData = snapshot.data ?? widget.athleteData;

        // Extract data
        final int currentStars = liveAthleteData['stars'] ?? 0;
        final int currentXp = (liveAthleteData['currentXp'] ?? 0).toInt();
        final int selectedOutfitId = liveAthleteData['selectedOutfit'] ?? 101;
        final int selectedShoeId = liveAthleteData['selectedShoe'] ?? 201;
        final int selectedEquipmentId = liveAthleteData['selectedEquipment'] ?? 301;
        final List<dynamic> unlockedItems =
            liveAthleteData['unlockedItems'] ?? [];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Character & Gear',
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
                  onPressed: _loadProfile,
                  tooltip: "Refresh Inventory",
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
                  // --- Currency Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCurrencyChip(context, Icons.stars_rounded, currentStars, Colors.amber, "Stars"),
                        _buildCurrencyChip(context, Icons.bolt_rounded, currentXp, colorScheme.primary, "XP"),
                      ],
                    ),
                  ),

                  // --- Avatar Showcase Area ---
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Glow
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Main Avatar
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.5), width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 100,
                                  color: _viewModel.outfits
                                          .firstWhere((k) => k['id'] == selectedOutfitId,
                                              orElse: () => _viewModel.outfits.first)['color']
                                      as Color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Equipment Badge (floating below)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _viewModel.equipment
                                            .firstWhere((e) => e['id'] == selectedEquipmentId,
                                                orElse: () => _viewModel.equipment.first)['icon']
                                        as IconData,
                                    size: 20,
                                    color: _viewModel.equipment
                                            .firstWhere((b) => b['id'] == selectedEquipmentId,
                                                orElse: () => _viewModel.equipment.first)['color']
                                        as Color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _viewModel.equipment
                                        .firstWhere((e) => e['id'] == selectedEquipmentId,
                                            orElse: () => _viewModel.equipment.first)['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Customization Panel ---
                  Expanded(
                    flex: 6,
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
                        children: [
                          // Tab Bar
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                labelColor: colorScheme.onPrimary,
                                unselectedLabelColor: colorScheme.onSurfaceVariant,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Outfits'),
                                  Tab(text: 'Shoes'),
                                  Tab(text: 'Gear'),
                                ],
                              ),
                            ),
                          ),

                          // Grid Content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildGridWrapper(
                                  _buildItemGrid(_viewModel.outfits, 'Outfit',
                                      selectedOutfitId, liveAthleteData, unlockedItems),
                                ),
                                _buildGridWrapper(
                                  _buildItemGrid(_viewModel.shoes, 'Shoe', selectedShoeId,
                                      liveAthleteData, unlockedItems),
                                ),
                                _buildGridWrapper(
                                  _buildItemGrid(_viewModel.equipment, 'Equipment',
                                      selectedEquipmentId, liveAthleteData, unlockedItems),
                                ),
                              ],
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

  Widget _buildGridWrapper(Widget grid) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: grid,
    );
  }

  // --- Helper Widgets ---
  Widget _buildCurrencyChip(BuildContext context, IconData icon, int value, Color color, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, 
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(
    List<Map<String, dynamic>> items,
    String category,
    int selectedId,
    Map<String, dynamic> liveAthleteData,
    List<dynamic> unlockedItems,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item['id'] == selectedId;
        final isDefaultUnlocked = item['unlocked'] == true;
        final isUnlocked = isDefaultUnlocked || unlockedItems.contains(item['id']);
        final color = item['color'] as Color;

        return GestureDetector(
          onTap: () => _handleItemSelect(item, category, liveAthleteData),
          child: Opacity(
            opacity: _viewModel.isLoading ? 0.6 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected 
                    ? colorScheme.primaryContainer.withOpacity(0.3) 
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : (isUnlocked ? Colors.transparent : colorScheme.outlineVariant.withOpacity(0.5)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  // Main Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 32,
                          color: isUnlocked ? color : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          item['name'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isUnlocked
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price or Status
                      if (!isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded, size: 12, color: Colors.amber[800]),
                              const SizedBox(width: 4),
                              Text(
                                '${item['cost']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),

                  // Equipped Badge
                  if (isSelected && isUnlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),

                  // Lock Icon
                  if (!isUnlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
}