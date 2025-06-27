// ignore: unused_import
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/location_provider.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:dyme_eat/widgets/mood_selector.dart';
import 'package:dyme_eat/widgets/restaurant_card.dart';
import 'package:dyme_eat/widgets/skeleton_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

// Providers
final selectedMoodProvider = StateProvider<Mood?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
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
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),

          // --- Mood Selector ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text("Or find by mood...",
                style: Theme.of(context).textTheme.titleMedium),
          ),
          MoodSelector(
            onMoodSelected: (mood) =>
                ref.read(selectedMoodProvider.notifier).state = mood,
          ),

          // --- Near Me Toggle ---
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sort by nearest",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: isNearMeToggled,
                  onChanged: (value) =>
                      ref.read(nearMeToggleProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Restaurant List ---
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                if (isNearMeToggled) {
                  final userLocationAsync = ref.watch(userLocationProvider);
                  return userLocationAsync.when(
                    data: (userPos) {
                      final sortedRestaurants = _filterAndSortRestaurants(
                        restaurants,
                        selectedMood,
                        searchQuery,
                        userPos,
                      );
                      return _buildRestaurantList(sortedRestaurants);
                    },
                    loading: () => _buildShimmerLoading(),
                    error: (err, stack) => Center(child: Text(err.toString())),
                  );
                } else {
                  final filteredRestaurants = _filterAndSortRestaurants(
                    restaurants,
                    selectedMood,
                    searchQuery,
                    null,
                  );
                  return _buildRestaurantList(filteredRestaurants);
                }
              },
              loading: () => _buildShimmerLoading(),
              error: (err, stack) => Center(
                child: Text(
                  'Could not load restaurants.\nPlease check your connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

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
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      RestaurantDetailScreen(restaurant: restaurant)),
            );
          },
        );
      },
    );
  }

  List<Restaurant> _filterAndSortRestaurants(
    List<Restaurant> restaurants,
    Mood? mood,
    String query,
    Position? userPosition,
  ) {
    // Filter
    List<Restaurant> filtered = restaurants.where((r) {
      final matchesMood = mood == null ||
          r.cuisineTags.any((tag) => mood.associatedTags.contains(tag));
      final matchesSearch =
          query.isEmpty || r.name.toLowerCase().contains(query.toLowerCase());
      return matchesMood && matchesSearch;
    }).toList();

    // Sort by distance if location is provided
    if (userPosition != null) {
      filtered.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
    );
  }
}
