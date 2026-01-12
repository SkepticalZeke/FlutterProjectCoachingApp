import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Cloud Run API URL
  static const String _baseUrl = 'https://ikh-service-150046979522.asia-southeast1.run.app';

  // Store authentication token and user data in memory
  static String? _authToken;
  static String? _coachUid;

  // Store the authentication token and coach UID
  void setToken(String token, {String? coachUid}) {
    _authToken = token;
    _coachUid = coachUid;
  }

  // Clear the authentication token and user data
  Future<void> clearToken() async {
    _authToken = null;
    _coachUid = null;
  }

  // Get current token
  String? get token => _authToken;

  // Get current coach UID
  String? get coachUid => _coachUid;

  // Helper to get headers with Auth Token
  Map<String, String> _getHeaders({bool authRequired = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (authRequired && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool authRequired = true}) async {
    final headers = _getHeaders(authRequired: authRequired);

    debugPrint('📡 API Request: POST $_baseUrl$endpoint');
    if (kDebugMode) {
      debugPrint('📤 Request data: ${data.toString()}');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Request timeout after 30 seconds');
          throw ApiException('Request timeout. Please check your internet connection.', 408);
        },
      );

      debugPrint('📡 API Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('📥 Response data: ${responseData.toString()}');
        }
        return responseData;
      } else {
        // Try to parse error message from response
        String errorMessage = 'Request failed';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? errorBody['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        debugPrint('❌ API Error [${response.statusCode}]: $errorMessage');
        throw ApiException(errorMessage, response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Network error: ${e.toString()}');
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }
}

// Custom exception class for better error handling
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}