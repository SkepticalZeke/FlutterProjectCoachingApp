import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = false; // For purchase transactions
  String? _errorMessage;

  // 3. Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Provides a live stream of the athlete's main document
  Stream<DocumentSnapshot> get athleteStream {
    return _dbRepo.getAthleteDocumentStream(_athleteId);
  }

  // 4. Initialization
  void initialize(Map<String, dynamic> athleteData) {
    _athleteId = athleteData['id'];
  }

  // 5. Mock Shop Data (This could be moved to its own repository later)
  final List<Map<String, dynamic>> outfits = const [
    {'id': 101, 'name': 'Green Tank', 'icon': Icons.person, 'unlocked': true, 'color': Colors.green},
    {'id': 102, 'name': 'Blue T-Shirt', 'icon': Icons.person, 'unlocked': false, 'cost': 1500, 'color': Colors.blue},
    {'id': 103, 'name': 'Red Jersey', 'icon': Icons.person, 'unlocked': false, 'cost': 3000, 'color': Colors.red},
  ];
  final List<Map<String, dynamic>> shoes = const [
    {'id': 201, 'name': 'Black Trainers', 'icon': Icons.style, 'unlocked': true, 'color': Colors.grey},
    {'id': 202, 'name': 'Orange Runners', 'icon': Icons.style, 'unlocked': false, 'cost': 1000, 'color': Colors.orange},
  ];
  final List<Map<String, dynamic>> equipment = const [
    {'id': 301, 'name': 'Water Bottle', 'icon': Icons.water_drop, 'unlocked': true, 'color': Colors.blue},
    {'id': 302, 'name': 'Gold Dumbbell', 'icon': Icons.fitness_center, 'unlocked': false, 'cost': 4000, 'color': Colors.amber},
  ];

  // 6. Logic
  Future<String> selectOrBuyItem(
    Map<String, dynamic> item,
    String category,
    Map<String, dynamic> liveAthleteData,
  ) async {
    _setLoading(true);
    _clearError();

    final int itemId = item['id'] as int;
    final String fieldToUpdate = 'selected$category'; // e.g., 'selectedOutfit'

    final List<dynamic> unlockedItems = liveAthleteData['unlockedItems'] ?? [];
    final bool isDefaultUnlocked = item['unlocked'] == true;
    final bool isUnlocked = isDefaultUnlocked || unlockedItems.contains(itemId);

    try {
      if (isUnlocked) {
        // --- ITEM IS ALREADY OWNED: EQUIP IT ---
        await _dbRepo.equipItem(_athleteId, fieldToUpdate, itemId);
        _setLoading(false);
        return '${item['name']} equipped!';
      } else {
        // --- ITEM IS LOCKED: ATTEMPT TO BUY IT ---
        final int itemCost = item['cost'];
        final int currentStars = liveAthleteData['stars'] ?? 0;

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
      return e.toString(); // Return error message
    }
  }

  // 7. Helper functions
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}