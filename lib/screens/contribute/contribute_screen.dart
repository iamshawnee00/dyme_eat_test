// lib/screens/contribute/contribute_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/screens/contribute/add_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch a few restaurants to review
final reviewableRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('restaurants')
      .limit(10)
      .get();
  return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
});

class ContributeScreen extends ConsumerWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(reviewableRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute'),
      ),
      body: restaurantsAsync.when(
        data: (restaurants) => ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return ListTile(
              title: Text(restaurant.name),
              subtitle: const Text("Tap to share your Taste"),
              trailing: const Icon(Icons.rate_review_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewScreen(restaurant: restaurant),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Could not load restaurants.')),
      ),
    );
  }
}
