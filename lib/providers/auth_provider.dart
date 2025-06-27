// File: lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/app_user.dart';

// Service class to handle all Firebase Authentication logic.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth, this._firestore);

  // Stream to listen to authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get the current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign Up with Email & Password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create a new user document in Firestore
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(appUser.toFirestore());
      }
    } on FirebaseAuthException catch (e) {
      // Provide a user-friendly error message
      throw Exception('Failed to sign up: ${e.message}');
    }
  }

  // Sign In with Email & Password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign in: ${e.message}');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

// Provider for the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

// Provider to stream the authentication state (the user object).
// This is what most of the app will listen to.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

