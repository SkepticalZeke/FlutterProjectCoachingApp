class Athlete {
  final String id;
  final String name;
  final String pin;
  final String coachUid;
  final int level;
  final int streak;
  final double progress;
  final String status;
  final String skillFocus;
  final String difficulty;
  final int stars;
  final int selectedOutfit;
  final int selectedShoe;
  final int selectedEquipment;
  final double currentXp;
  final double requiredXp;
  final int totalXp;

  Athlete({
    required this.id,
    required this.name,
    required this.pin,
    required this.coachUid,
    required this.level,
    required this.streak,
    required this.progress,
    required this.status,
    required this.skillFocus,
    required this.difficulty,
    required this.stars,
    required this.selectedOutfit,
    required this.selectedShoe,
    required this.selectedEquipment,
    required this.currentXp,
    required this.requiredXp,
    required this.totalXp,
  });

  factory Athlete.fromMap(Map<String, dynamic> data, String id) {
    return Athlete(
      id: id,
      name: data['name'] ?? '',
      pin: data['pin'] ?? '',
      coachUid: data['coachUid'] ?? '',
      level: data['level'] ?? 1,
      streak: data['streak'] ?? 0,
      progress: data['progress']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Training Not Started',
      skillFocus: data['skillFocus'] ?? 'General',
      difficulty: data['difficulty'] ?? 'Easy',
      stars: data['stars'] ?? 0,
      selectedOutfit: data['selectedOutfit'] ?? 101,
      selectedShoe: data['selectedShoe'] ?? 201,
      selectedEquipment: data['selectedEquipment'] ?? 301,
      currentXp: data['currentXp']?.toDouble() ?? 0.0,
      requiredXp: data['requiredXp']?.toDouble() ?? 1000.0,
      totalXp: data['totalXp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pin': pin,
      'coachUid': coachUid,
      'level': level,
      'streak': streak,
      'progress': progress,
      'status': status,
      'skillFocus': skillFocus,
      'difficulty': difficulty,
      'stars': stars,
      'selectedOutfit': selectedOutfit,
      'selectedShoe': selectedShoe,
      'selectedEquipment': selectedEquipment,
      'currentXp': currentXp,
      'requiredXp': requiredXp,
      'totalXp': totalXp,
    };
  }
}