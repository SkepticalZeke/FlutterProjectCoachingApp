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
  final bool embedded; // When true, no Scaffold wrapper (used in shell)
  const AvatarView({super.key, required this.athleteData, this.embedded = false});

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
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        final int selectedEquipmentId =
            liveAthleteData['selectedEquipment'] ?? 301;
        final List<dynamic> unlockedItems =
            liveAthleteData['unlockedItems'] ?? [];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'My Athlete & Gear',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: !widget.embedded,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Manual Refresh Button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.purple),
                  onPressed: _loadProfile,
                ),
              )
            ],
          ),
          // DARK BACKGROUND
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF121212),
            child: SafeArea(
              child: Column(
                children: [
                  // --- Currency and Avatar Display ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCurrencyChip(
                            Icons.stars_rounded, currentStars, Colors.amber),
                        const SizedBox(width: 16),
                        _buildCurrencyChip(
                            Icons.bolt_rounded, currentXp, Colors.blue),
                      ],
                    ),
                  ),

                  // --- Avatar Display Area ---
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow/Backdrop
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E1E1E),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                        ),
                        // Character
                        Icon(
                          Icons.person,
                          size: 140,
                          color: _viewModel.outfits.firstWhere(
                                  (k) => k['id'] == selectedOutfitId,
                                  orElse: () => _viewModel.outfits.first)[
                              'color'] as Color,
                        ),
                        // Equipment (Overlay)
                        Positioned(
                          bottom: 40,
                          right: 80,
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Icon(
                              _viewModel.equipment.firstWhere(
                                      (e) => e['id'] == selectedEquipmentId,
                                      orElse: () => _viewModel.equipment
                                          .first)['icon'] as IconData,
                              size: 40,
                              color: _viewModel.equipment.firstWhere(
                                      (b) => b['id'] == selectedEquipmentId,
                                      orElse: () => _viewModel.equipment
                                          .first)['color'] as Color,
                            ),
                          ),
                        ),
                        // Shoe Indicator (Abstract representation)
                        Positioned(
                          bottom: 30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.3), blurRadius: 4)
                                ]),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.do_not_step,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  _viewModel.shoes.firstWhere(
                                      (s) => s['id'] == selectedShoeId,
                                      orElse: () =>
                                          _viewModel.shoes.first)['name'],
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Customization Tabs ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: Colors.purple,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
                        Tab(icon: Icon(Icons.style), text: 'Shoes'),
                        Tab(icon: Icon(Icons.fitness_center), text: 'Gear'),
                      ],
                    ),
                  ),

                  // --- Customization Content ---
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 6. Wrap Grids in RefreshIndicator to allow Pull-to-Refresh
                          RefreshIndicator(
                            onRefresh: _loadProfile,
                            child: _buildItemGrid(
                                _viewModel.outfits,
                                'Outfit',
                                selectedOutfitId,
                                liveAthleteData,
                                unlockedItems),
                          ),
                          RefreshIndicator(
                            onRefresh: _loadProfile,
                            child: _buildItemGrid(
                                _viewModel.shoes,
                                'Shoe',
                                selectedShoeId,
                                liveAthleteData,
                                unlockedItems),
                          ),
                          RefreshIndicator(
                            onRefresh: _loadProfile,
                            child: _buildItemGrid(
                                _viewModel.equipment,
                                'Equipment',
                                selectedEquipmentId,
                                liveAthleteData,
                                unlockedItems),
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

  // --- Helper Widgets (UI Only) ---
  Widget _buildCurrencyChip(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
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
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
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
      padding: const EdgeInsets.only(bottom: 20),
      // AlwaysScrollableScrollPhysics ensures Pull-to-Refresh works even if list is short
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item['id'] == selectedId;
        final isDefaultUnlocked = item['unlocked'] == true;
        final isUnlocked =
            isDefaultUnlocked || unlockedItems.contains(item['id']);

        return GestureDetector(
          onTap: () =>
              _handleItemSelect(item, category, liveAthleteData),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.purple.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isSelected ? Colors.purple : Colors.grey.shade700,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: _viewModel.isLoading ? 0.5 : 1.0,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Icon(item['icon'] as IconData,
                              size: 48,
                              color: isUnlocked
                                  ? (item['color'] as Color)
                                  : Colors.grey.shade300),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          children: [
                            Text(
                              item['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stars_rounded,
                                        size: 14, color: Colors.amber[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item['cost']}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[500]),
                                    ),
                                  ],
                                ),
                              ),
                            if (isSelected && isUnlocked)
                              Text('EQUIPPED',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green[400],
                                      letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isUnlocked)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(Icons.lock,
                          size: 18, color: Colors.grey.shade400),
                    ),
                  if (isSelected)
                    Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}