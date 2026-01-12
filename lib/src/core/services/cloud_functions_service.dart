import 'package:cloud_functions/cloud_functions.dart';

/*
  Cloud Functions Service
  Handles all communication with Firebase Cloud Functions
  All functions are deployed in asia-southeast1 region
*/
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  // ==========================================================================
  // ATHLETE FUNCTIONS
  // ==========================================================================

  /// Get all athletes (coach only - filtered by coachId on backend)
  Future<List<Map<String, dynamic>>> getAthletes() async {
    try {
      final result = await _functions.httpsCallable('getAthletes').call();
      if (result.data['success'] == true) {
        return List<Map<String, dynamic>>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get athletes');
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single athlete by ID
  Future<Map<String, dynamic>> getAthlete(String athleteId) async {
    try {
      final result = await _functions.httpsCallable('getAthlete').call({
        'athleteId': athleteId,
      });
      if (result.data['success'] == true) {
        return Map<String, dynamic>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get athlete');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new athlete
  Future<String> createAthlete({
    required String name,
    required String pin,
    required String coachId,
  }) async {
    try {
      final result = await _functions.httpsCallable('createAthlete').call({
        'name': name,
        'email': '$name@athlete.local', // Placeholder email
        'pin': pin,
        'coachId': coachId,
        'level': 1,
        'streak': 0,
        'progress': 0.0,
        'status': 'Training Not Started',
        'skillFocus': 'General',
        'difficulty': 'Easy',
        'stars': 0,
        'unlockedItems': [101, 201, 301],
        'selectedOutfit': 101,
        'selectedShoe': 201,
        'selectedEquipment': 301,
        'currentXp': 0.0,
        'requiredXp': 1000.0,
        'totalXp': 0,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to create athlete');
    } catch (e) {
      rethrow;
    }
  }

  /// Update athlete details
  Future<void> updateAthlete({
    required String athleteId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final result = await _functions.httpsCallable('updateAthlete').call({
        'athleteId': athleteId,
        'updates': updates,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to update athlete');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an athlete (admin only)
  Future<void> deleteAthlete(String athleteId) async {
    try {
      final result = await _functions.httpsCallable('deleteAthlete').call({
        'athleteId': athleteId,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to delete athlete');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // COACH FUNCTIONS
  // ==========================================================================

  /// Get all coaches (admin only)
  Future<List<Map<String, dynamic>>> getCoaches() async {
    try {
      final result = await _functions.httpsCallable('getCoaches').call();
      if (result.data['success'] == true) {
        return List<Map<String, dynamic>>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get coaches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single coach by ID
  Future<Map<String, dynamic>> getCoach(String coachId) async {
    try {
      final result = await _functions.httpsCallable('getCoach').call({
        'coachId': coachId,
      });
      if (result.data['success'] == true) {
        return Map<String, dynamic>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get coach');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new coach
  Future<String> createCoach({
    required String uid,
    required String email,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCoach').call({
        'uid': uid,
        'email': email,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to create coach');
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // DRILL FUNCTIONS
  // ==========================================================================

  /// Get all drills (filtered by role on backend)
  Future<List<Map<String, dynamic>>> getDrills({String? status}) async {
    try {
      final result = await _functions.httpsCallable('getDrills').call({
        if (status != null) 'status': status,
      });
      if (result.data['success'] == true) {
        return List<Map<String, dynamic>>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get drills');
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single drill by ID
  Future<Map<String, dynamic>> getDrill(String drillId) async {
    try {
      final result = await _functions.httpsCallable('getDrill').call({
        'drillId': drillId,
      });
      if (result.data['success'] == true) {
        return Map<String, dynamic>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get drill');
    } catch (e) {
      rethrow;
    }
  }

  /// Create/assign a new drill to an athlete (coach only)
  Future<String> createDrill({
    required String title,
    required String athleteId,
    String? description,
    String? videoUrl,
    int? xp,
    String? skillFocus,
  }) async {
    try {
      final result = await _functions.httpsCallable('createDrill').call({
        'title': title,
        'athleteId': athleteId,
        'description': description,
        'videoUrl': videoUrl,
        'xp': xp,
        'skillFocus': skillFocus,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to create drill');
    } catch (e) {
      rethrow;
    }
  }

  /// Submit a drill for review (athlete only)
  Future<void> submitDrill({
    required String drillId,
    String? videoUrl,
    String? notes,
  }) async {
    try {
      final result = await _functions.httpsCallable('submitDrill').call({
        'drillId': drillId,
        'videoUrl': videoUrl,
        'notes': notes,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to submit drill');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Review a drill (coach only)
  Future<void> reviewDrill({
    required String drillId,
    required bool approved,
    String? feedback,
    int? rating,
  }) async {
    try {
      final result = await _functions.httpsCallable('reviewDrill').call({
        'drillId': drillId,
        'approved': approved,
        'feedback': feedback,
        'rating': rating,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to review drill');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // NOTIFICATION FUNCTIONS
  // ==========================================================================

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final result = await _functions.httpsCallable('getNotifications').call();
      if (result.data['success'] == true) {
        return List<Map<String, dynamic>>.from(result.data['data']);
      }
      throw Exception(result.data['message'] ?? 'Failed to get notifications');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      final result =
          await _functions.httpsCallable('markNotificationRead').call({
        'notificationId': notificationId,
      });
      if (result.data['success'] != true) {
        throw Exception(
            result.data['message'] ?? 'Failed to mark notification as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    try {
      final result =
          await _functions.httpsCallable('markAllNotificationsRead').call();
      if (result.data['success'] != true) {
        throw Exception(
            result.data['message'] ?? 'Failed to mark all notifications as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    try {
      final result =
          await _functions.httpsCallable('clearNotifications').call();
      if (result.data['success'] != true) {
        throw Exception(
            result.data['message'] ?? 'Failed to clear notifications');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // APP-SPECIFIC FUNCTIONS
  // ==========================================================================

  /// Create coach profile during registration
  Future<String> createCoachProfile({
    required String uid,
    required String email,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCoachProfile').call({
        'uid': uid,
        'email': email,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to create coach profile');
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new athlete to a coach
  Future<String> addAthlete({
    required String name,
    required String pin,
  }) async {
    try {
      final result = await _functions.httpsCallable('addAthlete').call({
        'name': name,
        'pin': pin,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to add athlete');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a coach drill template
  Future<String> createCoachDrill({
    required String name,
    required String goal,
    required String skillFocus,
    required double xp,
    required String videoUrl,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCoachDrill').call({
        'name': name,
        'goal': goal,
        'skillFocus': skillFocus,
        'xp': xp,
        'videoUrl': videoUrl,
      });
      if (result.data['success'] == true) {
        return result.data['data']['id'];
      }
      throw Exception(result.data['message'] ?? 'Failed to create coach drill');
    } catch (e) {
      rethrow;
    }
  }

  /// Assign a drill to an athlete
  Future<void> assignDrill({
    required String athleteId,
    required Map<String, dynamic> drillData,
  }) async {
    try {
      final result = await _functions.httpsCallable('assignDrill').call({
        'athleteId': athleteId,
        'drillData': drillData,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to assign drill');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a drill (athlete submits)
  Future<void> completeDrill({
    required String athleteId,
    required String drillId,
    required String drillName,
    required int xpGained,
    required String coachVideoUrl,
    required String athleteVideoUrl,
    required String coachUid,
  }) async {
    try {
      final result = await _functions.httpsCallable('completeDrill').call({
        'athleteId': athleteId,
        'drillId': drillId,
        'drillName': drillName,
        'xpGained': xpGained,
        'coachVideoUrl': coachVideoUrl,
        'athleteVideoUrl': athleteVideoUrl,
        'coachUid': coachUid,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to complete drill');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit a review for a drill
  Future<void> submitReview({
    required String athleteId,
    required String logId,
    required bool isApproved,
    required String feedback,
  }) async {
    try {
      final result = await _functions.httpsCallable('submitReview').call({
        'athleteId': athleteId,
        'logId': logId,
        'isApproved': isApproved,
        'feedback': feedback,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to submit review');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update athlete details (difficulty, focus, notes)
  Future<void> updateAthleteDetails({
    required String athleteId,
    required String difficulty,
    required String skillFocus,
    required String notes,
  }) async {
    try {
      final result = await _functions.httpsCallable('updateAthleteDetails').call({
        'athleteId': athleteId,
        'difficulty': difficulty,
        'skillFocus': skillFocus,
        'notes': notes,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to update athlete details');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add a rest day for an athlete
  Future<void> addRestDay(String athleteId) async {
    try {
      final result = await _functions.httpsCallable('addRestDay').call({
        'athleteId': athleteId,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to add rest day');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update athlete profile (name, pin)
  Future<void> updateAthleteProfile({
    required String athleteId,
    String? newName,
    String? newPin,
  }) async {
    try {
      final result = await _functions.httpsCallable('updateAthleteProfile').call({
        'athleteId': athleteId,
        if (newName != null) 'newName': newName,
        if (newPin != null) 'newPin': newPin,
      });
      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to update athlete profile');
      }
    } catch (e) {
      rethrow;
    }
  }
}
