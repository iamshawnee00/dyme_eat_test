import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider that creates a stream of the restaurant list from Firestore.
final restaurantListProvider = StreamProvider<List<Restaurant>>((ref) {
  // Access the Firestore instance.
  final firestore = FirebaseFirestore.instance;

  // Create a stream that listens to the 'restaurants' collection.
  // We are ordering them by name and limiting to 100 for performance.
  return firestore
      .collection('restaurants')
      .orderBy('name')
      .limit(100) 
      .snapshots()
      .map((snapshot) {
        // For each document in the snapshot, convert it to a Restaurant object.
        return snapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc))
            .toList();
      });
});
