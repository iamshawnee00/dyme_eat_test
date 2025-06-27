// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final int influencePoints;
  final String? foodiePersonality; // e.g., "TGNF"
  final bool foodieCrestRevealed;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.influencePoints = 0,
    this.foodiePersonality,
    this.foodieCrestRevealed = false,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      uid: snapshot.id,
      email: data?['email'],
      displayName: data?['displayName'],
      photoURL: data?['photoURL'],
      influencePoints: data?['influencePoints'] ?? 0,
      foodiePersonality: data?['foodiePersonality'],
      foodieCrestRevealed: data?['foodieCrestRevealed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) "email": email,
      if (displayName != null) "displayName": displayName,
      if (photoURL != null) "photoURL": photoURL,
      "influencePoints": influencePoints,
      if (foodiePersonality != null) "foodiePersonality": foodiePersonality,
      "foodieCrestRevealed": foodieCrestRevealed,
    };
  }
}
