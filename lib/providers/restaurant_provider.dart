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


// New provider for trending restaurants (most reviewed)
final trendingRestaurantsProvider = StreamProvider<List<Restaurant>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .orderBy('reviewCount', descending: true)
      .limit(10) // We only need a few for a horizontal list
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList());
});

// New provider for recently added restaurants
final newRestaurantsProvider = StreamProvider<List<Restaurant>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList());
});

// New provider that searches for restaurants by name.
// It takes a search query as a parameter.
final searchRestaurantsProvider = StreamProvider.autoDispose.family<List<Restaurant>, String>((ref, query) {
  if (query.isEmpty) {
    return Stream.value([]); // Return an empty list if the query is empty
  }
  
  // This query finds restaurants where the name is greater than or equal to the query
  // and less than the query plus a special character, which is a common way
  // to implement "starts with" search in Firestore.
  return FirebaseFirestore.instance
      .collection('restaurants')
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: '$query\uf8ff')
      .limit(10) // Limit results for performance
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList());
});

