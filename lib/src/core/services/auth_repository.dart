import 'package:firebase_auth/firebase_auth.dart';

/*
  MODEL (M)
  This is the Auth Repository. Its only job is to talk to Firebase
  Authentication. It doesn't know about any ViewModels or Views.
  It just does its job and returns the user or throws an error.
*/
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registers a new coach with email and password
  // Returns the new User object on success, or throws an error
  Future<User?> registerCoachWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      // Re-throw the specific Firebase error to be handled by the ViewModel
      rethrow;
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Logs in a coach
  Future<User?> loginCoachWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Signs out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('An error occurred during sign out: $e');
    }
  }
  
  // Gets the current user (if any)
  User? get currentUser => _auth.currentUser;

  // Stream for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}