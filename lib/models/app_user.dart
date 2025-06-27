import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final int influencePoints;
  final String? foodiePersonality;
  final bool foodieCrestRevealed;
  final List<String> allergies;    // <-- NEW
  final List<String> preferences; // <-- NEW

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.influencePoints = 0,
    this.foodiePersonality,
    this.foodieCrestRevealed = false,
    this.allergies = const [],    // <-- NEW
    this.preferences = const [],  // <-- NEW
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
      allergies: List<String>.from(data?['allergies'] ?? []),      // <-- NEW
      preferences: List<String>.from(data?['preferences'] ?? []),  // <-- NEW
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
      "allergies": allergies,        // <-- NEW
      "preferences": preferences,    // <-- NEW
    };
  }
}