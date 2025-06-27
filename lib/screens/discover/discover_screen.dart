import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/location_provider.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:dyme_eat/widgets/mood_selector.dart';
import 'package:dyme_eat/widgets/restaurant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Providers for mood and search query remain the same
final selectedMoodProvider = StateProvider<Mood?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
// A new StateProvider for our "Near Me" toggle
final nearMeToggleProvider = StateProvider<bool>((ref) => false);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final selectedMood = ref.watch(selectedMoodProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isNearMeToggled = ref.watch(nearMeToggleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Restaurants')),
      body: Column(
        children: [
          // ... (Search Bar and Mood Selector UI remain the same) ...

          // --- Near Me Toggle ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sort by nearest", style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: isNearMeToggled,
                  onChanged: (value) {
                    ref.read(nearMeToggleProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Restaurant List ---
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                // If "Near Me" is toggled, we need the user's location to sort
                if (isNearMeToggled) {
                  final userLocationAsync = ref.watch(userLocationProvider);
                  return userLocationAsync.when(
                    data: (userPos) {
                      // Once we have the location, filter and sort the restaurants
                      final sortedRestaurants = _filterAndSortRestaurants(restaurants, selectedMood, searchQuery, userPos);
                      return _buildRestaurantList(sortedRestaurants);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text(err.toString())),
                  );
                } else {
                  // If "Near Me" is off, just filter without sorting by distance
                  final filteredRestaurants = _filterAndSortRestaurants(restaurants, selectedMood, searchQuery, null);
                  return _buildRestaurantList(filteredRestaurants);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(err.toString())),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build the ListView
  Widget _buildRestaurantList(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(child: Text('No restaurants match your filters.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant)));
          },
        );
      },
    );
  }

  // Helper function containing all filtering and sorting logic
  List<Restaurant> _filterAndSortRestaurants(List<Restaurant> restaurants, Mood? mood, String query, Position? userPosition) {
    // First, apply mood and search filters
    List<Restaurant> filtered = restaurants.where((r) {
      final matchesMood = mood == null || r.cuisineTags.any((tag) => mood.associatedTags.contains(tag));
      final matchesSearch = query.isEmpty || r.name.toLowerCase().contains(query.toLowerCase());
      return matchesMood && matchesSearch;
    }).toList();

    // If we have a user position, sort by distance
    if (userPosition != null) {
      filtered.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, a.location.latitude, a.location.longitude);
        final distanceB = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, b.location.latitude, b.location.longitude);
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }
}