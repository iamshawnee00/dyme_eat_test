// lib/models/restaurant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final List<String> cuisineTags;
  final Map<String, dynamic> overallTasteSignature; // Aggregated data

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.cuisineTags,
    required this.overallTasteSignature,
  });

  // <<< Add this factory method >>>
  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Restaurant(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Restaurant',
      address: data['address'] ?? 'No address',
      location: data['location'] ?? const GeoPoint(0, 0),
      cuisineTags: List<String>.from(data['cuisineTags'] ?? []),
      overallTasteSignature: Map<String, dynamic>.from(data['overallTasteSignature'] ?? {}),
    );
  }
}

// fromFirestore and toFirestore methods would be added here