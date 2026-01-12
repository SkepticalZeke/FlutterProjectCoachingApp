import 'package:flutter/material.dart';
// Import our Model
import '../../../core/services/database_repository.dart';

/*
  VIEW-MODEL (VM)
  This is the "brain" for the Athlete Avatar View.
*/
class AvatarViewModel extends ChangeNotifier {
  // 1. Repositories
  final DatabaseRepository _dbRepo = DatabaseRepository();

  // 2. State
  late String _athleteId;
  bool _isLoading = false;
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 4. Initialization
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }

  // 5. DATA FETCHING (Future)
  Future<Map<String, dynamic>?> fetchAthleteProfile() {
    return _dbRepo.getAthleteDocument(_athleteId);
  }

  // 6. LOGIC: Buy or Equip Item
  // This is the missing function!
  Future<String> purchaseOrEquipItem(
    Map<String, dynamic> item,
    Map<String, dynamic> currentData,
  ) async {
    _setLoading(true);
    _clearError();

    final int itemId = item['id'];
    
    // Determine category based on item ID or logic
    // (Simple logic: 100s=Outfit, 200s=Shoe, 300s=Equipment)
    String fieldToUpdate = 'selectedOutfit';
    if (itemId >= 200 && itemId < 300) fieldToUpdate = 'selectedShoe';
    if (itemId >= 300) fieldToUpdate = 'selectedEquipment';

    final List<dynamic> unlockedItems = currentData['unlockedItems'] ?? [];
    final bool isDefaultUnlocked = item['unlocked'] == true;
    final bool isUnlocked = isDefaultUnlocked || unlockedItems.contains(itemId);

    try {
      if (isUnlocked) {
        // --- EQUIPPING ---
        await _dbRepo.equipItem(_athleteId, fieldToUpdate, itemId);
        _setLoading(false);
        return '${item['name']} equipped!';
      } else {
        // --- BUYING ---
        final int itemCost = item['cost'] ?? 0;
        final int currentStars = currentData['stars'] ?? 0;

        await _dbRepo.buyItem(
          athleteId: _athleteId,
          itemId: itemId,
          itemCost: itemCost,
          currentStars: currentStars,
        );
        _setLoading(false);
        return 'Purchased ${item['name']}!';
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return e.toString();
    }
  }

  // 7. Helper functions
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
  
  // 8. SHOP DATA
  // (You can move this to a separate file later if it gets too big)
  final List<Map<String, dynamic>> outfits = const [
    {'id': 101, 'name': 'Green Tank', 'icon': Icons.person, 'unlocked': true, 'color': Colors.green},
    {'id': 102, 'name': 'Blue T-Shirt', 'icon': Icons.person, 'cost': 10, 'unlocked': false, 'color': Colors.blue},
    {'id': 103, 'name': 'Red Jersey', 'icon': Icons.person, 'cost': 25, 'unlocked': false, 'color': Colors.red},
    {'id': 104, 'name': 'Pro Gear', 'icon': Icons.person, 'cost': 50, 'unlocked': false, 'color': Colors.black},
  ];

  final List<Map<String, dynamic>> shoes = const [
    {'id': 201, 'name': 'Basic Runners', 'icon': Icons.directions_run, 'unlocked': true, 'color': Colors.grey},
    {'id': 202, 'name': 'Speedsters', 'icon': Icons.directions_run, 'cost': 15, 'unlocked': false, 'color': Colors.orange},
    {'id': 203, 'name': 'High Tops', 'icon': Icons.directions_run, 'cost': 30, 'unlocked': false, 'color': Colors.blueAccent},
  ];

  final List<Map<String, dynamic>> equipment = const [
    {'id': 301, 'name': 'Water Bottle', 'icon': Icons.fitness_center, 'unlocked': true, 'color': Colors.blue},
    {'id': 302, 'name': 'Dumbbells', 'icon': Icons.fitness_center, 'cost': 20, 'unlocked': false, 'color': Colors.grey},
    {'id': 303, 'name': 'Yoga Mat', 'icon': Icons.fitness_center, 'cost': 35, 'unlocked': false, 'color': Colors.purple},
  ];
}