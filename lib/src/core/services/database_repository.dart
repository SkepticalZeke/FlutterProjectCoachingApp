import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // We need auth to get the UID
import '../models/athlete.dart';

/*
  MODEL (M)
  This is the Database Repository. Its only job is to talk to
  Firestore. It's "dumb" and just does what it's told.
*/
class DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _coachUid => _auth.currentUser?.uid;

  // Creates the coach doc and their first athlete doc in one batch
  Future<void> createCoachAndFirstAthlete({
    required String coachUid,
    required String coachEmail,
    required String athleteName,
    required String athletePin,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      // 1. Create the Coach Document in 'coaches' collection
      DocumentReference coachRef =
          _firestore.collection('coaches').doc(coachUid);
      batch.set(coachRef, {
        'uid': coachUid,
        'email': coachEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Create the first Athlete Document in 'athletes' collection
      DocumentReference athleteRef = _firestore.collection('athletes').doc();
      batch.set(athleteRef, {
        'name': athleteName,
        'pin': athletePin,
        'coachUid': coachUid, // This links the athlete to the coach
        'level': 1,
        'streak': 0,
        'progress': 0.0,
        'status': 'Training Not Started',
        'skill_focus': 'General',
        'difficulty': 'Easy',
        'createdAt': FieldValue.serverTimestamp(),
        'stars': 0,
        'unlockedItems': [101, 201, 301], // Default unlocked items
        'selectedOutfit': 101,
        'selectedShoe': 201,
        'selectedEquipment': 301,
        'currentXp': 0.0,
        'requiredXp': 1000.0,
        'totalXp': 0,
        'skillProgress': {
          'General': 0.0,
          'Agility': 0.0,
          'Strength': 0.0,
          'Cardio': 0.0,
        },
      });

      // Commit both writes at the same time
      await batch.commit();
    } catch (e) {
      // Re-throw to be handled by ViewModel
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

  // Updates an athlete's details (difficulty, focus, notes)
  Future<void> updateAthleteDetails(String athleteId, String difficulty,
      String skillFocus, String notes) async {
    DocumentReference athleteRef =
        _firestore.collection('athletes').doc(athleteId);
    await athleteRef.update({
      'difficulty': difficulty,
      'skill_focus': skillFocus,
      'notes': notes,
    });
  }
  
  

  // Sets an athlete's status to a rest day
  Future<void> addRestDay(String athleteId) async {
    DocumentReference athleteRef =
        _firestore.collection('athletes').doc(athleteId);
    await athleteRef.update({
      'status': 'Rest Day (Completed)',
      'progress': 1.0,
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
    if (_coachUid == null) throw Exception('No coach logged in');
    await _firestore
        .collection('coaches')
        .doc(_coachUid)
        .collection('drills')
        .add({
      'name': name,
      'goal': goal,
      'skillFocus': skillFocus,
      'xp': xp,
      'videoUrl': videoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
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

  // Assigns a drill to an athlete
  Future<void> assignDrillToAthlete({
    required String athleteId,
    required Map<String, dynamic> drillData,
  }) async {
    if (_coachUid == null) throw Exception('No coach logged in');

    final athleteDrillsRef = _firestore
        .collection('athletes')
        .doc(athleteId)
        .collection('todayDrills');

    await athleteDrillsRef.add({
      'name': drillData['name'],
      'goal': drillData['goal'],
      'skillFocus': drillData['skillFocus'],
      'xp': drillData['xp'],
      'videoUrl': drillData['videoUrl'],
      'coachDrillId': drillData['id'], // Link to the original drill
      'coachUid': _coachUid, // ⭐️ NEW: For querying
      'athleteId': athleteId, // ⭐️ NEW: For querying
      'assignedAt': FieldValue.serverTimestamp(),
      'completed': false,
      'iconData': 0xe722, // video_library
    });
  }

  // Marks a drill as complete
  Future<void> completeDrill({
    required String athleteId,
    required String drillId,
    required String drillName,
    required int xpGained,
    required String coachVideoUrl,
    required String athleteVideoUrl,
    required String coachUid, // ⭐️ Pass this in
  }) async {
    final athleteRef = _firestore.collection('athletes').doc(athleteId);
    final drillRef = athleteRef.collection('todayDrills').doc(drillId);
    final logRef = athleteRef.collection('logs').doc();

    DocumentSnapshot athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists) throw Exception("Athlete document not found");

    final athleteData = athleteDoc.data() as Map<String, dynamic>;
    final String skillFocus = athleteData['skill_focus'] ?? 'General';
    final String skillProgressField = 'skillProgress.$skillFocus';

    WriteBatch batch = _firestore.batch();

    batch.update(drillRef, {
      'completed': true,
      'status': 'Pending Review',
      'athleteVideoUrl': athleteVideoUrl,
    });

    batch.set(logRef, {
      'drill': drillName,
      'status': 'Pending Review',
      'xp': xpGained,
      'date': FieldValue.serverTimestamp(),
      'skillFocus': skillFocus,
      'coachVideoUrl': coachVideoUrl,
      'athleteVideoUrl': athleteVideoUrl,
      'coachUid': coachUid, // ⭐️ NEW: For notifications
      'athleteId': athleteId, // ⭐️ NEW: For notifications
    });

    batch.update(athleteRef, {
      'totalXp': FieldValue.increment(xpGained),
      'currentXp': FieldValue.increment(xpGained),
      skillProgressField: FieldValue.increment(xpGained),
    });

    await batch.commit();
  }

  // Submits a review for a drill
  Future<void> submitReview({
    required String athleteId,
    required String logId,
    required bool isApproved,
    required String feedback,
  }) async {
    final newStatus = isApproved ? 'Approved' : 'Needs Work';
    final bonusXp = isApproved ? 25 : 0;

    final logRef = _firestore
        .collection('athletes')
        .doc(athleteId)
        .collection('logs')
        .doc(logId);
    final athleteRef = _firestore.collection('athletes').doc(athleteId);

    WriteBatch batch = _firestore.batch();

    batch.update(logRef, {
      'status': newStatus,
      'feedback': feedback,
    });

    if (isApproved) {
      batch.update(athleteRef, {
        'totalXp': FieldValue.increment(bonusXp),
        'currentXp': FieldValue.increment(bonusXp),
        'stars': FieldValue.increment(10), // Reward 10 stars
      });
    }

    // We also need to find the original drill in 'todayDrills' and update its status
    // For simplicity, we'll leave this for now, but in a real app, you'd link them.

    await batch.commit();
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


  Future<void> updateAthleteProfile({
    required String athleteId,
    String? newName,
    String? newPin,
  }) async {
    final Map<String, dynamic> updates = {};

    if (newName != null && newName.isNotEmpty) {
      updates['name'] = newName;
    }
    if (newPin != null && newPin.isNotEmpty) {
      updates['pin'] = newPin;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('athletes').doc(athleteId).update(updates);
    }
  }
}