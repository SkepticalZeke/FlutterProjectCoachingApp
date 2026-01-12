import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/athlete.dart';
import 'cloud_functions_service.dart';

/*
  MODEL (M)
  This is the Database Repository - Hybrid Architecture

  Uses Cloud Functions for:
  - All mutations (create, update, delete)
  - All write operations that require validation

  Uses direct Firestore for:
  - Real-time streams (snapshots)
  - Read operations that need instant updates

  This approach combines:
  - Security & validation from Cloud Functions
  - Real-time updates from Firestore streams
*/
class DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudFunctionsService _functions = CloudFunctionsService();

  String? get _coachUid => _auth.currentUser?.uid;

  // Creates the coach doc and their first athlete doc using Cloud Functions
  Future<void> createCoachAndFirstAthlete({
    required String coachUid,
    required String coachEmail,
    required String athleteName,
    required String athletePin,
  }) async {
    try {
      // Create coach profile via Cloud Function
      await _functions.createCoachProfile(
        uid: coachUid,
        email: coachEmail,
      );

      // Create first athlete via Cloud Function
      await _functions.addAthlete(
        name: athleteName,
        pin: athletePin,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Fetches a single athlete by name and PIN
  Future<Map<String, dynamic>?> getAthleteByNameAndPin(
      String name, String pin) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('athletes')
          .where('name', isEqualTo: name)
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final athleteDoc = snapshot.docs.first;
        final athleteData = athleteDoc.data() as Map<String, dynamic>;
        athleteData['id'] = athleteDoc.id; // Add the document ID
        return athleteData;
      } else {
        return null; // No match
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gets a live stream of all athletes for a specific coach
  Stream<QuerySnapshot> getAthletesStream(String coachUid) {
    return _firestore
        .collection('athletes')
        .where('coachUid', isEqualTo: coachUid)
        .snapshots();
  }

  // Gets a live stream of a single athlete's document
  Stream<DocumentSnapshot> getAthleteDocumentStream(String athleteId) {
    return _firestore.collection('athletes').doc(athleteId).snapshots();
  }

  // Gets a live stream of the drills assigned to an athlete
  Stream<QuerySnapshot> getTodayDrillsStream(String athleteId) {
    return _firestore
        .collection('athletes')
        .doc(athleteId)
        .collection('todayDrills')
        .snapshots();
  }

  // Gets a live stream of an athlete's completed logs
  Stream<QuerySnapshot> getAthleteLogsStream(String athleteId) {
    return _firestore
        .collection('athletes')
        .doc(athleteId)
        .collection('logs')
        .orderBy('date', descending: true)
        .limit(30) // Get last 30 logs
        .snapshots();
  }

  // Gets a live stream of all pending submissions for a coach
  Stream<QuerySnapshot> getPendingSubmissionsStream() {
    if (_coachUid == null) throw Exception('No coach logged in');
    return _firestore
        .collectionGroup('logs') // ⭐️ This is a Collection Group query
        .where('coachUid', isEqualTo: _coachUid)
        .where('status', isEqualTo: 'Pending Review')
        .snapshots();
  }

  // Updates an athlete's details via Cloud Function
  Future<void> updateAthleteDetails(String athleteId, String difficulty,
      String skillFocus, String notes) async {
    await _functions.updateAthleteDetails(
      athleteId: athleteId,
      difficulty: difficulty,
      skillFocus: skillFocus,
      notes: notes,
    );
  }

  // Sets an athlete's status to a rest day via Cloud Function
  Future<void> addRestDay(String athleteId) async {
    await _functions.addRestDay(athleteId);
  }

  // Creates a new drill for a coach via Cloud Function
  Future<void> createCoachDrill({
    required String name,
    required String goal,
    required String skillFocus,
    required double xp,
    required String videoUrl,
  }) async {
    if (_coachUid == null) throw Exception('No coach logged in');
    await _functions.createCoachDrill(
      name: name,
      goal: goal,
      skillFocus: skillFocus,
      xp: xp,
      videoUrl: videoUrl,
    );
  }

  // Gets a stream of all drills created by the current coach
  Stream<QuerySnapshot> getCoachDrillsStream() {
    if (_coachUid == null) throw Exception('No coach logged in');
    return _firestore
        .collection('coaches')
        .doc(_coachUid)
        .collection('drills')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Gets all drills associated with a specific coach's UID
  Stream<QuerySnapshot> getDrillsForCoach(String coachUid) {
    return _firestore
        .collection('coaches')
        .doc(coachUid)
        .collection('drills')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Assigns a drill to an athlete via Cloud Function
  Future<void> assignDrillToAthlete({
    required String athleteId,
    required Map<String, dynamic> drillData,
  }) async {
    if (_coachUid == null) throw Exception('No coach logged in');
    await _functions.assignDrill(
      athleteId: athleteId,
      drillData: drillData,
    );
  }

  // Marks a drill as complete via Cloud Function
  Future<void> completeDrill({
    required String athleteId,
    required String drillId,
    required String drillName,
    required int xpGained,
    required String coachVideoUrl,
    required String athleteVideoUrl,
    required String coachUid,
  }) async {
    await _functions.completeDrill(
      athleteId: athleteId,
      drillId: drillId,
      drillName: drillName,
      xpGained: xpGained,
      coachVideoUrl: coachVideoUrl,
      athleteVideoUrl: athleteVideoUrl,
      coachUid: coachUid,
    );
  }

  // Submits a review for a drill via Cloud Function
  Future<void> submitReview({
    required String athleteId,
    required String logId,
    required bool isApproved,
    required String feedback,
  }) async {
    await _functions.submitReview(
      athleteId: athleteId,
      logId: logId,
      isApproved: isApproved,
      feedback: feedback,
    );
  }

  // Registers a new athlete with the coach
  Future<Athlete> registerNewAthlete({
    required String name,
    required String pin,
    required String coachEmail,
  }) async {
    try {
      // First, find the coach by email
      final coachSnapshot = await _firestore
          .collection('coaches')
          .where('email', isEqualTo: coachEmail)
          .limit(1)
          .get();

      if (coachSnapshot.docs.isEmpty) {
        throw Exception('Coach with email $coachEmail not found');
      }

      final coachDoc = coachSnapshot.docs.first;
      final coachUid = coachDoc.id;

      // Create the athlete document
      final athleteRef = _firestore.collection('athletes').doc();
      final newAthlete = Athlete(
        id: athleteRef.id,
        name: name,
        pin: pin,
        coachUid: coachUid,
        level: 1,
        streak: 0,
        progress: 0.0,
        status: 'Training Not Started',
        skillFocus: 'General',
        difficulty: 'Easy',
        stars: 0,
        selectedOutfit: 101,
        selectedShoe: 201,
        selectedEquipment: 301,
        currentXp: 0.0,
        requiredXp: 1000.0,
        totalXp: 0,
      );

      await athleteRef.set(newAthlete.toMap());

      return newAthlete;
    } catch (e) {
      rethrow;
    }
  }

  // --- Athlete Avatar/Store Logic ---
  Future<void> equipItem(String athleteId, String field, int itemId) async {
    await _firestore.collection('athletes').doc(athleteId).update({field: itemId});
  }

  Future<void> buyItem({
    required String athleteId,
    required int itemId,
    required int itemCost,
    required int currentStars,
  }) async {
    final athleteRef = _firestore.collection('athletes').doc(athleteId);

    if (currentStars < itemCost) {
      throw Exception('Need ${itemCost - currentStars} more Stars to unlock!');
    }

    await _firestore.runTransaction((transaction) async {
      transaction.update(athleteRef, {
        'stars': FieldValue.increment(-itemCost),
        'unlockedItems': FieldValue.arrayUnion([itemId])
      });
    });
  }


  // Update athlete profile via Cloud Function
  Future<void> updateAthleteProfile({
    required String athleteId,
    String? newName,
    String? newPin,
  }) async {
    await _functions.updateAthleteProfile(
      athleteId: athleteId,
      newName: newName,
      newPin: newPin,
    );
  }

  // Add new athlete via Cloud Function
  Future<void> addNewAthlete({
    required String coachUid,
    required String name,
    required String pin,
  }) async {
    await _functions.addAthlete(
      name: name,
      pin: pin,
    );
  }
}