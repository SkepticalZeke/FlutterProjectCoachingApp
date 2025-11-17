import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth

/*
  MODEL (M)
  This is the Storage Repository. Its only job is to
  upload files to Firebase Storage.
*/
class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Get auth instance

  // Uploads an athlete's video submission
  Future<String> uploadSubmissionVideo(File file, String athleteId) async {
    try {
      final String videoFileName =
          '${athleteId}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      UploadTask uploadTask = _storage
          .ref('athlete_submissions/$athleteId/$videoFileName')
          .putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Re-throw to be handled by ViewModel
      rethrow;
    }
  }

  // Uploads a coach's example drill video
  Future<String> uploadCoachDrillVideo(File file) async {
    final String? coachUid = _auth.currentUser?.uid;
    if (coachUid == null) {
      throw Exception("No coach is logged in.");
    }
    try {
      final String videoFileName =
          '${coachUid}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      UploadTask uploadTask = _storage
          .ref('coach_drills/$coachUid/$videoFileName')
          .putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Re-throw to be handled by ViewModel
      rethrow;
    }
  }
}