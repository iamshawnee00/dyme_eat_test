// Corrected import path for cloud_firestore
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum to define the type of tip. This helps enforce data consistency.
enum TipType { parking, location, general }

class PathfinderTip {
  final String id;
  final String authorId;
  final String restaurantId;
  final TipType tipType;
  final String tipContent;
  final Timestamp timestamp;
  final int upvotes;
  final bool isVerified;

  PathfinderTip({
    required this.id,
    required this.authorId,
    required this.restaurantId,
    required this.tipType,
    required this.tipContent,
    required this.timestamp,
    this.upvotes = 0,
    this.isVerified = false,
  });

  // Factory constructor to create a PathfinderTip instance from a Firestore document.
  factory PathfinderTip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();

    // Defensive coding: Provide default values if data is null or fields are missing.
    return PathfinderTip(
      id: snapshot.id,
      authorId: data?['authorId'] ?? '',
      restaurantId: data?['restaurantId'] ?? '',
      // Safely parse the enum from a string, defaulting to 'general' if invalid.
      tipType: TipType.values.byName(data?['tipType'] ?? 'general'),
      tipContent: data?['tipContent'] ?? '',
      timestamp: data?['timestamp'] ?? Timestamp.now(), // Default to current time
      upvotes: data?['upvotes'] ?? 0,
      isVerified: data?['isVerified'] ?? false,
    );
  }

  // Method to convert a PathfinderTip instance into a map for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'restaurantId': restaurantId,
      'tipType': tipType.name, // Store the enum as a string
      'tipContent': tipContent,
      'timestamp': timestamp,
      'upvotes': upvotes,
      'isVerified': isVerified,
    };
  }
}
