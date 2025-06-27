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
  final List<String> imageUrls; // <-- NEW FIELD

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.cuisineTags,
    required this.overallTasteSignature,
    this.reviewCount = 0,
    this.createdAt,
    this.imageUrls = const [], // <-- NEW FIELD with default value
  });

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
      // Read the image URLs from Firestore
      imageUrls: List<String>.from(data['imageUrls'] ?? []), // <-- NEW FIELD
    );
  }
}
