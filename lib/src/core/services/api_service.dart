import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Replace with your actual Cloud Run URL after deployment
  static const String _baseUrl = 'https://ikh-service-150046979522.asia-southeast1.run.app';

  // Helper to get headers with Auth Token
  Future<Map<String, String>> _getHeaders({bool authRequired = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (authRequired) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool authRequired = true}) async {
    final headers = await _getHeaders(authRequired: authRequired);
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}