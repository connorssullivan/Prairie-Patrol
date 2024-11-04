//Name: Auth.dart
// Desc: This class is used for authenticating users

import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  // Create an instance of FirebaseAuth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Method to sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // Method to sign out the current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Method to get the current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}