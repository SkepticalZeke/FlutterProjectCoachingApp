import 'package:flutter/material.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Currency/XP
  final int currentStars = 2500;
  final int currentXp = 450;

  // Mock Customization Data
  final List<Map<String, dynamic>> kits = [
    {'id': 1, 'name': 'Classic Green', 'icon': Icons.accessibility_new, 'unlocked': true, 'color': Colors.green},
    {'id': 2, 'name': 'Lightning Blue', 'icon': Icons.accessibility_new, 'unlocked': false, 'cost': 1500, 'color': Colors.blue},
    {'id': 3, 'name': 'Red Dragon', 'icon': Icons.accessibility_new, 'unlocked': false, 'cost': 3000, 'color': Colors.red},
    {'id': 4, 'name': 'Camo Gear', 'icon': Icons.accessibility_new, 'unlocked': false, 'cost': 5000, 'color': Colors.brown},
  ];

  final List<Map<String, dynamic>> boots = [
    {'id': 1, 'name': 'Basic Black', 'icon': Icons.sports_soccer, 'unlocked': true, 'color': Colors.black},
    {'id': 2, 'name': 'Speed Striker', 'icon': Icons.sports_soccer, 'unlocked': false, 'cost': 1000, 'color': Colors.orange},
    {'id': 3, 'name': 'Pro Touch', 'icon': Icons.sports_soccer, 'unlocked': false, 'cost': 2500, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> balls = [
    {'id': 1, 'name': 'Standard White', 'icon': Icons.circle, 'unlocked': true, 'color': Colors.grey},
    {'id': 2, 'name': 'Golden Ace', 'icon': Icons.circle, 'unlocked': false, 'cost': 4000, 'color': Colors.amber},
    {'id': 3, 'name': 'Fire Ball', 'icon': Icons.circle, 'unlocked': false, 'cost': 3500, 'color': Colors.redAccent},
  ];

  // Selected state
  int _selectedKitId = 1;
  int _selectedBootId = 1;
  int _selectedBallId = 1;
  
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

  void _handleItemSelect(int itemId, List<Map<String, dynamic>> itemList, String category) {
    final item = itemList.firstWhere((i) => i['id'] == itemId);
    
    if (item['unlocked'] == true) {
      setState(() {
        if (category == 'Kit') _selectedKitId = itemId;
        if (category == 'Boot') _selectedBootId = itemId;
        if (category == 'Ball') _selectedBallId = itemId;
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
          SnackBar(content: Text('Need ${item['cost'] - currentStars} Stars to unlock!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Player & Gear'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                _buildCurrencyChip(Icons.bolt, currentXp, Colors.blue),
              ],
            ),
          ),
          
          // Avatar Display Area
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background/Field
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.lightGreen[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                ),
                // Mock Player Icon (Color depends on selected kit)
                Icon(
                  Icons.sports_soccer, 
                  size: 100, 
                  color: kits.firstWhere((k) => k['id'] == _selectedKitId)['color'] as Color,
                ),
                // Mock Ball Icon (Small, near player's feet)
                Positioned(
                  bottom: 40,
                  right: 140,
                  child: Icon(
                    Icons.circle,
                    size: 20,
                    color: balls.firstWhere((b) => b['id'] == _selectedBallId)['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // --- 2. Customization Tabs ---
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(icon: Icon(Icons.checkroom), text: 'Kits'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Boots'),
              Tab(icon: Icon(Icons.circle_notifications), text: 'Balls'),
            ],
          ),

          // --- 3. Customization Content ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemGrid(kits, 'Kit', _selectedKitId),
                _buildItemGrid(boots, 'Boot', _selectedBootId),
                _buildItemGrid(balls, 'Ball', _selectedBallId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(IconData icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildItemGrid(List<Map<String, dynamic>> items, String category, int selectedId) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Adjust for card shape
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
              color: isUnlocked ? Colors.white : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.secondary : (isUnlocked ? Colors.grey.shade300 : Colors.grey.shade400),
                width: isSelected ? 4 : 1,
              ),
              boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), blurRadius: 8)] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, size: 50, color: item['color'] as Color),
                const SizedBox(height: 10),
                Text(
                  item['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isUnlocked ? Colors.black87 : Colors.grey[600],
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[700]),
                      ),
                    ],
                  ),
                if (isSelected && isUnlocked)
                  const Text('EQUIPPED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }
}