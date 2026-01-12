import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/*
  MODEL (M)
  This is the Storage Repository. Its only job is to
  upload files to the backend API.
*/
class StorageRepository {
  final ApiService _api = ApiService();
  static const String _baseUrl = 'https://ikh-service-150046979522.asia-southeast1.run.app';

  // Uploads an athlete's video submission
  Future<String> uploadSubmissionVideo(File file, String athleteId) async {
    try {
      final response = await _uploadVideo(
        file: file,
        uploadType: 'athlete_submission',
        athleteId: athleteId,
      );
      return response['downloadUrl'];
    } catch (e) {
      // Re-throw to be handled by ViewModel
      rethrow;
    }
  }

  // Uploads a coach's example drill video
  Future<String> uploadCoachDrillVideo(File file) async {
    try {
      final response = await _uploadVideo(
        file: file,
        uploadType: 'coach_drill',
      );
      return response['downloadUrl'];
    } catch (e) {
      // Re-throw to be handled by ViewModel
      rethrow;
    }
  }

  // Private helper method to upload video using multipart/form-data
  Future<Map<String, dynamic>> _uploadVideo({
    required File file,
    required String uploadType,
    String? athleteId,
  }) async {
    try {
      final token = _api.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl/api/upload/video');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['uploadType'] = uploadType;
      if (athleteId != null) {
        request.fields['athleteId'] = athleteId;
      }

      // Add video file
      final videoStream = http.ByteStream(file.openRead());
      final videoLength = await file.length();
      final multipartFile = http.MultipartFile(
        'video',
        videoStream,
        videoLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // 5 minute timeout for large videos
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse JSON response
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
}