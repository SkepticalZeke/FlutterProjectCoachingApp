import 'package:flutter/foundation.dart';
import '../models/athlete.dart';
import 'api_service.dart'; // Import the helper

class DatabaseRepository {
  final ApiService _api = ApiService(); // Use the API helper

  // --- WRITES: MOVED TO CLOUD RUN ---

Future<void> createCoachProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    // We utilize the API Service to send data to the server
    // Note: authRequired is true by default, which is correct because 
    // the user is logged in immediately after registration.
    await _api.post('/api/coach/create-profile', {
      'uid': uid,
      'name': name,
      'email': email,
    });
  }
  // Registers a new athlete with the coach
  Future<Athlete?> registerNewAthlete({
    required String name,
    required String pin,
    required String coachEmail,
  }) async {
    // Logic moved to backend endpoint: POST /api/athlete/register
    final response = await _api.post('/api/athlete/register', {
      'name': name,
      'pin': pin,
      'coachEmail': coachEmail,
    });

    // We reconstruct the Athlete object from the server response
    if (response != null) {
      return Athlete.fromMap(response, response['id']);
    }
    return null;
  }

  // Marks a drill as complete (Complex logic with XP calculation)
  Future<void> completeDrill({
    required String athleteId,
    required String drillId,
    required String drillName,
    required int xpGained,
    required String coachVideoUrl,
    required String athleteVideoUrl,
    required String coachUid,
  }) async {
    // Logic moved to backend: POST /api/drill/complete
    await _api.post('/api/drill/complete', {
      'athleteId': athleteId,
      'drillId': drillId,
      'drillName': drillName,
      'xpGained': xpGained,
      'coachVideoUrl': coachVideoUrl,
      'athleteVideoUrl': athleteVideoUrl,
      'coachUid': coachUid,
    });
  }

  // Submits a review for a drill
  Future<void> submitReview({
    required String athleteId,
    required String logId,
    required bool isApproved,
    required String feedback,
  }) async {
    await _api.post('/api/review/submit', {
      'athleteId': athleteId,
      'logId': logId,
      'isApproved': isApproved,
      'feedback': feedback,
    });
  }

  // Creates a new drill for a coach
  Future<void> createCoachDrill({
    required String name,
    required String goal,
    required String skillFocus,
    required double xp,
    required String videoUrl,
  }) async {
    await _api.post('/api/drill/create', {
      'name': name,
      'goal': goal,
      'skillFocus': skillFocus,
      'xp': xp,
      'videoUrl': videoUrl,
    });
  }

  // Assigns a drill to an athlete
  Future<void> assignDrillToAthlete({
    required String athleteId,
    required Map<String, dynamic> drillData,
  }) async {
    await _api.post('/api/drill/assign', {
      'athleteId': athleteId,
      'drillData': drillData,
    });
  }

  // Buying items (Transaction now happens on server)
  Future<void> buyItem({
    required String athleteId,
    required int itemId,
    required int itemCost,
    required int currentStars,
  }) async {
    await _api.post('/api/store/buy', {
      'athleteId': athleteId,
      'itemId': itemId,
      'itemCost': itemCost,
    });
  }

  // Updates an athlete's details
  Future<void> updateAthleteDetails(String athleteId, String difficulty,
      String skillFocus, String notes) async {
    await _api.post('/api/athlete/update-details', {
      'athleteId': athleteId,
      'difficulty': difficulty,
      'skillFocus': skillFocus,
      'notes': notes,
    });
  }

  Future<void> addRestDay(String athleteId) async {
     await _api.post('/api/athlete/rest-day', {
      'athleteId': athleteId,
    });
  }
  
  Future<void> equipItem(String athleteId, String field, int itemId) async {
    // Simple updates can technically stay direct, but for consistency, move to API
    await _api.post('/api/athlete/equip', {
      'athleteId': athleteId,
      'field': field,
      'itemId': itemId,
    });
  }

  Future<void> updateAthleteProfile({
    required String athleteId,
    String? newName,
    String? newPin,
  }) async {
    await _api.post('/api/athlete/update-profile', {
      'athleteId': athleteId,
      'newName': newName,
      'newPin': newPin,
    });
  }

  Future<void> addNewAthlete({
    required String coachUid,
    required String name,
    required String pin,
  }) async {
    await _api.post('/api/coach/add-athlete', {
      'coachUid': coachUid,
      'name': name,
      'pin': pin,
    });
  }

  // --- READS: KEEP DIRECT (HYBRID APPROACH) ---
  // We keep streams direct to Firestore for performance and simplicity
  // in receiving real-time updates.

  // Fetches a single athlete by name and PIN (Login)
  // This can technically move to API for security, but direct read is faster
  Future<Map<String, dynamic>?> getAthleteByNameAndPin(
      String name, String pin) async {
    try {
      // 1. Send the login request to the server
      final response = await _api.post('/api/athlete/login', {
        'name': name,
        'pin': pin,
      });

      // 2. The server returns the athlete data directly if successful
      return response; 
      
    } catch (e) {
      // If the server returns 401 (Incorrect PIN) or 404 (Not Found),
      // the ApiService usually throws an exception.
      
      // We return null here to let the ViewModel handle the "Invalid login" state
      // just like it did before.
      debugPrint("Login failed: $e");
      return null; 
    }
  }

  Future<List<Map<String, dynamic>>> getAthletes(String coachUid) async {
    final response = await _api.post('/api/coach/get-athletes', {
      'coachUid': coachUid,
    });
    // Ensure response is a list
    return List<Map<String, dynamic>>.from(response);
  }

  // Get single athlete document
  // CHANGED: Stream -> Future
  Future<Map<String, dynamic>?> getAthleteDocument(String athleteId) async {
     try {
       final response = await _api.post('/api/athlete/get', {
        'athleteId': athleteId,
      });
      return response;
     } catch (e) {
       return null;
     }
  }

  // Get today's drills
  // CHANGED: Stream -> Future<List>
  Future<List<Map<String, dynamic>>> getTodayDrills(String athleteId) async {
    final response = await _api.post('/api/athlete/get-drills', {
      'athleteId': athleteId,
    });
    return List<Map<String, dynamic>>.from(response);
  }

  // Get athlete logs
  // CHANGED: Stream -> Future<List>
  Future<List<Map<String, dynamic>>> getAthleteLogs(String athleteId) async {
    final response = await _api.post('/api/athlete/get-logs', {
      'athleteId': athleteId,
    });
    return List<Map<String, dynamic>>.from(response);
  }

  // Get pending reviews for coach
  // CHANGED: Stream -> Future<List>
  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    // Note: The server handles identifying the coach via the Auth Token in ApiService
    final response = await _api.post('/api/coach/get-pending', {});
    return List<Map<String, dynamic>>.from(response);
  }

  // Get coach's drill library
  // CHANGED: Stream -> Future<List>
  Future<List<Map<String, dynamic>>> getCoachDrills() async {
    final response = await _api.post('/api/coach/get-drills', {});
    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch drills for a specific coach (Used by Athlete View)
  Future<List<Map<String, dynamic>>> getDrillsForCoach(String coachUid) async {
    try {
      final response = await _api.post('/api/athlete/get-coach-drills', {
        'coachUid': coachUid,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching coach drills: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registerAthleteSelf({
    required String username,
    required String pin,
  }) async {
    // Note: authRequired: false because they aren't logged in yet
    final response = await _api.post('/auth/athlete/register-self', {
      'username': username,
      'pin': pin,
    }, authRequired: false);
    
    return Map<String, dynamic>.from(response);
  }

  // Get a single drill
  Future<Map<String, dynamic>?> getDrill(String drillId) async {
    try {
      final response = await _api.post('/api/coach/get-drill', {
        'drillId': drillId,
      });
      return response;
    } catch (e) {
      debugPrint("Error fetching drill: $e");
      return null;
    }
  }

  // Delete a drill
  Future<void> deleteDrill(String drillId) async {
    await _api.post('/api/coach/delete-drill', {
      'drillId': drillId,
    });
  }

  // Update a drill (metadata only - no video upload)
  Future<void> updateDrill({
    required String drillId,
    required String name,
    required String goal,
    required String skillFocus,
    required double xp,
  }) async {
    await _api.post('/api/coach/update-drill', {
      'drillId': drillId,
      'name': name,
      'goal': goal,
      'skillFocus': skillFocus,
      'xp': xp,
    });
  }

  // 2. New: Coach Linking Logic
  Future<void> linkAthlete(String connectionCode) async {
    await _api.post('/api/coach/link-athlete', {
      'connectionCode': connectionCode,
    });
  }
}