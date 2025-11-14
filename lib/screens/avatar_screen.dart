import 'package:flutter/material.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Currency/XP (XP matches dashboard)
  final int currentStars = 2500;
  final int currentXp = 450;

  // 1. Mock Data refactored: General Fitness
  final List<Map<String, dynamic>> outfits = [
    {
      'id': 1,
      'name': 'Green Tank',
      'icon': Icons.person,
      'unlocked': true,
      'color': Colors.green
    },
    {
      'id': 2,
      'name': 'Blue T-Shirt',
      'icon': Icons.person,
      'unlocked': false,
      'cost': 1500,
      'color': Colors.blue
    },
    {
      'id': 3,
      'name': 'Red Jersey',
      'icon': Icons.person,
      'unlocked': false,
      'cost': 3000,
      'color': Colors.red
    },
    {
      'id': 4,
      'name': 'Camo Tank',
      'icon': Icons.person,
      'unlocked': false,
      'cost': 5000,
      'color': Colors.brown
    },
  ];

  final List<Map<String, dynamic>> shoes = [
    {
      'id': 1,
      'name': 'Black Trainers',
      'icon': Icons.style, // Changed icon
      'unlocked': true,
      'color': Colors.grey[700]
    },
    {
      'id': 2,
      'name': 'Orange Runners',
      'icon': Icons.style,
      'unlocked': false,
      'cost': 1000,
      'color': Colors.orange
    },
    {
      'id': 3,
      'name': 'Purple Trainers',
      'icon': Icons.style,
      'unlocked': false,
      'cost': 2500,
      'color': Colors.purple
    },
  ];

  final List<Map<String, dynamic>> equipment = [
    {
      'id': 1,
      'name': 'Water Bottle',
      'icon': Icons.water_drop, // Changed icon
      'unlocked': true,
      'color': Colors.blue
    },
    {
      'id': 2,
      'name': 'Gold Dumbbell',
      'icon': Icons.fitness_center, // Changed icon
      'unlocked': false,
      'cost': 4000,
      'color': Colors.amber
    },
    {
      'id': 3,
      'name': 'Yoga Mat',
      'icon': Icons.self_improvement, // Changed icon
      'unlocked': false,
      'cost': 3500,
      'color': Colors.pinkAccent
    },
  ];

  // 2. State refactored
  int _selectedOutfitId = 1;
  int _selectedShoeId = 1;
  int _selectedEquipmentId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 3. Logic refactored
  void _handleItemSelect(
      int itemId, List<Map<String, dynamic>> itemList, String category) {
    final item = itemList.firstWhere((i) => i['id'] == itemId);

    if (item['unlocked'] == true) {
      setState(() {
        if (category == 'Outfit') _selectedOutfitId = itemId;
        if (category == 'Shoe') _selectedShoeId = itemId;
        if (category == 'Equipment') _selectedEquipmentId = itemId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} selected!')),
      );
    } else {
      // Logic for buying the item
      if (currentStars >= item['cost']) {
        // --- Firebase Placeholder: Spend currency and update state ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item['name']}! Now select it.')),
        );
        // In a real app, you would set item['unlocked'] = true and deduct stars
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Need ${item['cost'] - currentStars} Stars to unlock!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. UI Theme: Get theme from context
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // 5. Text refactored
        title: const Text('My Athlete & Gear'),
        // 6. UI Theme: Removed colors, uses main.dart theme
      ),
      body: Column(
        children: [
          // --- 1. Currency and Avatar Display ---
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

          // 7. UI Theme: Avatar Display Area
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                // Mock Athlete Icon (Color depends on selected outfit)
                Icon(
                  Icons.person, // Changed from sports_soccer
                  size: 100,
                  // 8. Logic refactored
                  color: outfits
                      .firstWhere((k) => k['id'] == _selectedOutfitId)['color'] as Color,
                ),
                // Mock Equipment Icon
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: Icon(
                    // 9. Logic refactored
                    equipment.firstWhere(
                            (e) => e['id'] == _selectedEquipmentId)['icon'] as IconData,
                    size: 30,
                    color: equipment.firstWhere(
                            (b) => b['id'] == _selectedEquipmentId)['color'] as Color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- 10. UI Theme: Customization Tabs ---
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              // 11. Text refactored
              Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
              Tab(icon: Icon(Icons.style), text: 'Shoes'), // Changed icon
              Tab(icon: Icon(Icons.construction), text: 'Equipment'), // Changed icon
            ],
          ),

          // --- 12. Logic refactored: Customization Content ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemGrid(outfits, 'Outfit', _selectedOutfitId),
                _buildItemGrid(shoes, 'Shoe', _selectedShoeId),
                _buildItemGrid(equipment, 'Equipment', _selectedEquipmentId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 13. UI Theme: Currency Chip
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

  // 14. UI Theme: Item Grid
  Widget _buildItemGrid(
      List<Map<String, dynamic>> items, String category, int selectedId) {
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
        final isUnlocked = item['unlocked'] == true;

        return GestureDetector(
          onTap: () => _handleItemSelect(item['id'] as int, items, category),
          child: Container(
            decoration: BoxDecoration(
              // Use theme surface color
              color: isUnlocked
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // Use primary color for selection
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
                    // Use theme text color
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
                      // Amber for "cost" is good, keep it
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
                  // Green for "equipped" is good, keep it
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