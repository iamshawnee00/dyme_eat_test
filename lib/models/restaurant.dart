import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final List<String> cuisineTags;
  final Map<String, dynamic> overallTasteSignature;
  final int reviewCount;
  final Timestamp? createdAt;
  final List<String> imageUrls;
  final List<String> tags; // <-- NEW FIELD
  final String? operatingHours; // e.g., "10:00 AM - 10:00 PM"
  final String? website;
  final String? phoneNumber;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.cuisineTags,
    required this.overallTasteSignature,
    this.reviewCount = 0,
    this.createdAt,
    this.imageUrls = const [],
    this.tags = const [], // <-- NEW with default value
    this.operatingHours,
    this.website,
    this.phoneNumber,
  });

  // Factory constructor to create an instance from a Firestore document
  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Restaurant(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Restaurant',
      address: data['address'] ?? 'No address',
      location: data['location'] ?? const GeoPoint(0, 0),
      cuisineTags: List<String>.from(data['cuisineTags'] ?? []),
      overallTasteSignature: Map<String, dynamic>.from(data['overallTasteSignature'] ?? {}),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []), // <-- NEW
      operatingHours: data['operatingHours'], // Can be null
      website: data['website'],
      phoneNumber: data['phoneNumber'],
    );
  }

  // NEW: Factory constructor to create an instance from a map (like the one from our Cloud Function)
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Restaurant',
      address: map['address'] ?? 'No address',
      // Provide default values for fields not present in the map
      location: const GeoPoint(0, 0),
      cuisineTags: List<String>.from(map['cuisineTags'] ?? []),
      overallTasteSignature: Map<String, dynamic>.from(map['overallTasteSignature'] ?? {}),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: map['createdAt'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}
