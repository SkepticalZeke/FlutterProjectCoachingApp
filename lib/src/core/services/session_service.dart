import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/*
  SESSION SERVICE
  This service manages user session persistence using SharedPreferences.
  It stores login state information so users don't need to log in again
  when they close and reopen the app.
*/
class SessionService {
  static const String _userTypeKey = 'user_type'; // 'coach' or 'athlete'
  static const String _athleteDataKey = 'athlete_data_json'; // For athlete login
  static const String _isLoggedInKey = 'is_logged_in';

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Initialize SharedPreferences
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Ensure initialization before using preferences
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  // ===== SAVE SESSION (Called after successful login) =====
  
  /// Save athlete session after successful login
  Future<void> saveAthleteSession(Map<String, dynamic> athleteData) async {
    try {
      await _ensureInitialized();
      
      // Convert athlete data map to JSON string
      final String athleteJson = _encodeAthleteData(athleteData);
      
      await Future.wait([
        _prefs.setString(_userTypeKey, 'athlete'),
        _prefs.setString(_athleteDataKey, athleteJson),
        _prefs.setBool(_isLoggedInKey, true),
      ]);
    } catch (e) {
      throw Exception('Error saving athlete session: $e');
    }
  }

  /// Save coach session after successful login
  Future<void> saveCoachSession() async {
    try {
      await _ensureInitialized();
      
      await Future.wait([
        _prefs.setString(_userTypeKey, 'coach'),
        _prefs.setBool(_isLoggedInKey, true),
      ]);
    } catch (e) {
      throw Exception('Error saving coach session: $e');
    }
  }

  // ===== RETRIEVE SESSION (Called on app startup) =====

  /// Get the saved user type ('coach', 'athlete', or null if no session)
  Future<String?> getUserType() async {
    await _ensureInitialized();
    return _prefs.getString(_userTypeKey);
  }

  /// Get the saved athlete data (only valid if user type is 'athlete')
  Future<Map<String, dynamic>?> getAthleteData() async {
    try {
      await _ensureInitialized();
      final String? athleteJson = _prefs.getString(_athleteDataKey);
      if (athleteJson == null) return null;
      return _decodeAthleteData(athleteJson);
    } catch (e) {
      // If there's an error decoding, clear the session
      await clearSession();
      return null;
    }
  }

  /// Check if there's an active session
  Future<bool> isSessionActive() async {
    await _ensureInitialized();
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // ===== CLEAR SESSION (Called on logout) =====

  /// Clear all session data when user logs out
  Future<void> clearSession() async {
    try {
      await _ensureInitialized();
      await Future.wait([
        _prefs.remove(_userTypeKey),
        _prefs.remove(_athleteDataKey),
        _prefs.remove(_isLoggedInKey),
      ]);
    } catch (e) {
      throw Exception('Error clearing session: $e');
    }
  }

  // ===== HELPER METHODS FOR JSON SERIALIZATION =====

  /// Encode athlete data map to JSON string
  String _encodeAthleteData(Map<String, dynamic> data) {
    // Use jsonEncode for proper type preservation
    try {
      return jsonEncode(data);
    } catch (e) {
      throw Exception('Failed to encode athlete data: $e');
    }
  }

  /// Decode JSON string back to athlete data map
  Map<String, dynamic> _decodeAthleteData(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Decoded data is not a Map');
    } catch (e) {
      throw Exception('Failed to decode athlete data: $e');
    }
  }
}
