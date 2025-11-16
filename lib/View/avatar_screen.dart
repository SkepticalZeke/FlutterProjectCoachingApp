import 'package:flutter/material.dart';
// ⭐️ ADD FIREBASE IMPORT ⭐️
import 'package:cloud_firestore/cloud_firestore.dart';

// ⭐️ 1. CONSTRUCTOR UPDATED ⭐️
class AvatarScreen extends StatefulWidget {
  final Map<String, dynamic> athleteData;
  const AvatarScreen({super.key, required this.athleteData});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ⭐️ GET FIREBASE INSTANCE and ATHLETE ID ⭐️
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _athleteId;

  // ⭐️ REMOVED MOCK (currentStars, currentXp) ⭐️

  // Mock Customization Data (This can be moved to Firestore later)
  final List<Map<String, dynamic>> outfits = [
    {
      'id': 101, // ⭐️ Made IDs unique
      'name': 'Green Tank',
      'icon': Icons.person,
      'unlocked': true, // Default unlocked
      'color': Colors.green
    },
    {
      'id': 102,
      'name': 'Blue T-Shirt',
      'icon': Icons.person,
      'unlocked': false,
      'cost': 1500,
      'color': Colors.blue
    },
    {
      'id': 103,
      'name': 'Red Jersey',
      'icon': Icons.person,
      'unlocked': false,
      'cost': 3000,
      'color': Colors.red
    },
  ];

  final List<Map<String, dynamic>> shoes = [
    {
      'id': 201, // ⭐️ Made IDs unique
      'name': 'Black Trainers',
      'icon': Icons.style,
      'unlocked': true, // Default unlocked
      'color': Colors.grey[700]
    },
    {
      'id': 202,
      'name': 'Orange Runners',
      'icon': Icons.style,
      'unlocked': false,
      'cost': 1000,
      'color': Colors.orange
    },
  ];

  final List<Map<String, dynamic>> equipment = [
    {
      'id': 301, // ⭐️ Made IDs unique
      'name': 'Water Bottle',
      'icon': Icons.water_drop,
      'unlocked': true, // Default unlocked
      'color': Colors.blue
    },
    {
      'id': 302,
      'name': 'Gold Dumbbell',
      'icon': Icons.fitness_center,
      'unlocked': false,
      'cost': 4000,
      'color': Colors.amber
    },
  ];

  // Selected state (will be loaded from Firebase)
  late int _selectedOutfitId;
  late int _selectedShoeId;
  late int _selectedEquipmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _athleteId = widget.athleteData['id'];

    // ⭐️ Load selections from athlete data (or set defaults)
    _selectedOutfitId = widget.athleteData['selectedOutfit'] ?? 101;
    _selectedShoeId = widget.athleteData['selectedShoe'] ?? 201;
    _selectedEquipmentId = widget.athleteData['selectedEquipment'] ?? 301;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ⭐️ 3. UPDATED ITEM SELECT/BUY FUNCTION ⭐️
  void _handleItemSelect(
    int itemId,
    List<Map<String, dynamic>> itemList,
    String category,
    Map<String, dynamic> liveAthleteData,
  ) async {
    final item = itemList.firstWhere((i) => i['id'] == itemId);

    // Get the list of items the athlete already owns
    final List<dynamic> unlockedItems = liveAthleteData['unlockedItems'] ?? [];
    final bool isDefaultUnlocked = item['unlocked'] == true;
    final bool isUnlocked =
        isDefaultUnlocked || unlockedItems.contains(item['id']);

    final athleteRef = _firestore.collection('athletes').doc(_athleteId);

    if (isUnlocked) {
      // --- ITEM IS ALREADY OWNED: EQUIP IT ---
      try {
        String fieldToUpdate = '';
        if (category == 'Outfit') {
          fieldToUpdate = 'selectedOutfit';
          _selectedOutfitId = itemId;
        }
        if (category == 'Shoe') {
          fieldToUpdate = 'selectedShoe';
          _selectedShoeId = itemId;
        }
        if (category == 'Equipment') {
          fieldToUpdate = 'selectedEquipment';
          _selectedEquipmentId = itemId;
        }

        await athleteRef.update({fieldToUpdate: itemId});
        setState(() {}); // Rebuild to show new selection

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} equipped!')),
        );
      } catch (e) {
        _showErrorSnackBar('Failed to equip item: $e');
      }
    } else {
      // --- ITEM IS LOCKED: ATTEMPT TO BUY IT ---
      final int itemCost = item['cost'];
      try {
        // Use a transaction to safely check stars and deduct
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(athleteRef);
          if (!snapshot.exists) {
            throw Exception("Athlete does not exist!");
          }

          int currentStars =
              (snapshot.data() as Map<String, dynamic>)['stars'] ?? 0;

          if (currentStars >= itemCost) {
            // 1. Deduct stars
            transaction.update(athleteRef, {
              'stars': FieldValue.increment(-itemCost),
              // 2. Add item to unlocked list
              'unlockedItems': FieldValue.arrayUnion([itemId])
            });
          } else {
            // Not enough stars, throw an error to be caught below
            throw Exception(
                'Need ${itemCost - currentStars} more Stars to unlock!');
          }
        });

        // If transaction is successful, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Purchased ${item['name']}!'),
              backgroundColor: Colors.green),
        );
        // We don't need to equip it, the stream will rebuild and show it as unlocked
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Athlete & Gear'),
      ),
      // ⭐️ 4. BODY WRAPPED IN STREAMBUILDER ⭐️
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('athletes').doc(_athleteId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Athlete data not found.'));
          }

          final liveAthleteData =
              snapshot.data!.data() as Map<String, dynamic>;

          // ⭐️ 5. GET LIVE DATA FOR CURRENCY ⭐️
          final int currentStars = liveAthleteData['stars'] ?? 0;
          final int currentXp = (liveAthleteData['currentXp'] ?? 0).toInt();

          // ⭐️ 6. LOAD LIVE SELECTIONS ⭐️
          // This ensures the avatar updates if data changes elsewhere
          _selectedOutfitId = liveAthleteData['selectedOutfit'] ?? 101;
          _selectedShoeId = liveAthleteData['selectedShoe'] ?? 201;
          _selectedEquipmentId = liveAthleteData['selectedEquipment'] ?? 301;

          return Column(
            children: [
              // --- 1. Currency and Avatar Display ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCurrencyChip(
                        Icons.stars, currentStars, Colors.amber),
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
                      color: outfits
                          .firstWhere((k) => k['id'] == _selectedOutfitId,
                              orElse: () => outfits.first)['color'] as Color,
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Icon(
                        equipment
                            .firstWhere(
                                (e) => e['id'] == _selectedEquipmentId,
                                orElse: () => equipment.first)['icon'] as IconData,
                        size: 30,
                        color: equipment
                            .firstWhere(
                                (b) => b['id'] == _selectedEquipmentId,
                                orElse: () => equipment.first)['color'] as Color,
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
                    theme.colorScheme.onSurface.withOpacity(0.7),
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
                    // ⭐️ 7. PASS LIVE DATA TO ITEM GRID ⭐️
                    _buildItemGrid(
                        outfits, 'Outfit', _selectedOutfitId, liveAthleteData),
                    _buildItemGrid(
                        shoes, 'Shoe', _selectedShoeId, liveAthleteData),
                    _buildItemGrid(equipment, 'Equipment', _selectedEquipmentId,
                        liveAthleteData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Currency Chip (Unchanged) ---
  Widget _buildCurrencyChip(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Darker for dark mode
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

  // ⭐️ 8. ITEM GRID WIDGET UPDATED ⭐️
  Widget _buildItemGrid(List<Map<String, dynamic>> items, String category,
      int selectedId, Map<String, dynamic> liveAthleteData) {
    final theme = Theme.of(context);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
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

        // ⭐️ 9. CHECK LIVE UNLOCKED STATUS ⭐️
        final List<dynamic> unlockedItems =
            liveAthleteData['unlockedItems'] ?? [];
        final bool isDefaultUnlocked = item['unlocked'] == true;
        final bool isUnlocked =
            isDefaultUnlocked || unlockedItems.contains(item['id']);

        return GestureDetector(
          // ⭐️ 10. PASS LIVE DATA TO HANDLER ⭐️
          onTap: () =>
              _handleItemSelect(item['id'] as int, items, category, liveAthleteData),
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isUnlocked
                        ? theme.colorScheme.onSurface.withOpacity(0.2)
                        : theme.colorScheme.onSurface.withOpacity(0.4)),
                width: isSelected ? 4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8)
                    ]
                  : null,
            ),
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
                        : theme.colorScheme.onSurface.withOpacity(0.5),
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
        );
      },
    );
  }
}