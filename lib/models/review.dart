// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String authorId;
  final String restaurantId;
  final String? dishId; // Optional, for dish-specific reviews
  final Timestamp timestamp;
  final Map<String, double> tasteDialData; // e.g., {"Wok Hei": 4.5, "Spiciness": 3.0}

  Review({
    required this.authorId,
    required this.restaurantId,
    this.dishId,
    required this.timestamp,
    required this.tasteDialData,
  });

  // << ADD THIS FACTORY CONSTRUCTOR >>
  factory Review.fromFirestore(Map<String, dynamic> data) {
    return Review(
      authorId: data['authorId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      dishId: data['dishId'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      tasteDialData: Map<String, double>.from(data['tasteDialData'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'restaurantId': restaurantId,
      if (dishId != null) 'dishId': dishId,
      'timestamp': timestamp,
      'tasteDialData': tasteDialData,
    };
  }
}
