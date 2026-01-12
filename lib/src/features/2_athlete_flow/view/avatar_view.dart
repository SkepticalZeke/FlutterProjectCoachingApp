import 'package:flutter/material.dart';
// Note: cloud_firestore import removed
// Import the new ViewModel
import '../viewmodel/avatar_viewmodel.dart';

/*
  VIEW (V)
  This is the UI. It is "dumb" and only talks to the ViewModel.
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
    // Call the ViewModel (Note: ensure your VM method name matches this)
    // Using 'purchaseOrEquipItem' to match the VM code provided earlier
    final result = await _viewModel.purchaseOrEquipItem(
      item,
      liveAthleteData,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor:
              _viewModel.errorMessage == null ? Colors.green : Colors.red,
        ),
      );
      // 4. IMPORTANT: Refresh the profile to show new Stars balance / Equipped item
      _loadProfile();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          appBar: AppBar(
            title: const Text('My Athlete & Gear'),
            actions: [
              // Manual Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProfile,
              )
            ],
          ),
          body: Column(
            children: [
              // --- Currency and Avatar Display ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCurrencyChip(Icons.stars, currentStars, Colors.amber),
                    _buildCurrencyChip(
                        Icons.bolt, currentXp, theme.colorScheme.primary),
                  ],
                ),
              ),

              // --- Avatar Display Area ---
              Container(
                height: 180,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                    ),
                    Icon(
                      Icons.person,
                      size: 100,
                      color: _viewModel.outfits
                          .firstWhere((k) => k['id'] == selectedOutfitId,
                              orElse: () => _viewModel.outfits.first)['color']
                          as Color,
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Icon(
                        _viewModel.equipment
                                .firstWhere((e) => e['id'] == selectedEquipmentId,
                                    orElse: () => _viewModel.equipment.first)['icon']
                            as IconData,
                        size: 30,
                        color: _viewModel.equipment
                                .firstWhere((b) => b['id'] == selectedEquipmentId,
                                    orElse: () => _viewModel.equipment.first)['color']
                            as Color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Customization Tabs ---
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.7),
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
                  Tab(icon: Icon(Icons.style), text: 'Shoes'),
                  Tab(icon: Icon(Icons.construction), text: 'Equipment'),
                ],
              ),

              // --- Customization Content ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 6. Wrap Grids in RefreshIndicator to allow Pull-to-Refresh
                    RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: _buildItemGrid(_viewModel.outfits, 'Outfit',
                          selectedOutfitId, liveAthleteData, unlockedItems),
                    ),
                    RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: _buildItemGrid(_viewModel.shoes, 'Shoe', selectedShoeId,
                          liveAthleteData, unlockedItems),
                    ),
                    RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: _buildItemGrid(_viewModel.equipment, 'Equipment',
                          selectedEquipmentId, liveAthleteData, unlockedItems),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets (UI Only) ---
  Widget _buildCurrencyChip(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(
            value.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // AlwaysScrollableScrollPhysics ensures Pull-to-Refresh works even if list is short
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item['id'] == selectedId;
        final isDefaultUnlocked = item['unlocked'] == true;
        final isUnlocked = isDefaultUnlocked || unlockedItems.contains(item['id']);

        return GestureDetector(
          onTap: () =>
              _handleItemSelect(item, category, liveAthleteData),
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isUnlocked
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                width: isSelected ? 4 : 1,
              ),
            ),
            child: Opacity(
              opacity: _viewModel.isLoading ? 0.5 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData,
                      size: 50, color: item['color'] as Color),
                  const SizedBox(height: 10),
                  Text(
                    item['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (!isUnlocked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${item['cost']}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700]),
                        ),
                      ],
                    ),
                  if (isSelected && isUnlocked)
                    Text('EQUIPPED',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.green[400])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}