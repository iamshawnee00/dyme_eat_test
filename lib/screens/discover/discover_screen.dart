import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/location_provider.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:dyme_eat/widgets/mood_selector.dart';
import 'package:dyme_eat/widgets/restaurant_card.dart';
import 'package:dyme_eat/widgets/skeleton_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tab 1: Personalized Recommendations
final personalizedDiscoveryProvider = FutureProvider<List<Restaurant>>((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user == null || user.foodiePersonality == null) return [];

  final tagMap = { "RAKK": "pedas-giler", "CAMK": "lepak" };
  final personalityTag = tagMap[user.foodiePersonality];
  if (personalityTag == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('restaurants')
      .where('tags', arrayContains: personalityTag)
      .limit(20)
      .get();

  return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
});

// Tab 2: Discover All Setup
final selectedMoodProvider = StateProvider<Mood?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final nearMeToggleProvider = StateProvider<bool>((ref) => false);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Discover"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Recommended"),
              Tab(text: "Discover All"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RecommendedTab(),
            _DiscoverAllTab(),
          ],
        ),
      ),
    );
  }
}

// -------- TAB 1: RECOMMENDED --------
class _RecommendedTab extends ConsumerWidget {
  const _RecommendedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(personalizedDiscoveryProvider);

    return recommendationsAsync.when(
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "We're still learning your taste! Review more places to get personalized recommendations.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return RestaurantCard(
              restaurant: restaurant,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RestaurantDetailScreen(restaurant: restaurant)));
              },
            );
          },
        );
      },
      loading: () => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(itemCount: 5, itemBuilder: (_, __) => const SkeletonCard()),
      ),
      error: (e, s) => Center(child: Text("Error: ${e.toString()}")),
    );
  }
}

// -------- TAB 2: DISCOVER ALL --------
class _DiscoverAllTab extends ConsumerWidget {
  const _DiscoverAllTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final selectedMood = ref.watch(selectedMoodProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isNearMeToggled = ref.watch(nearMeToggleProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
            ),
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).state = value,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text("Or find by mood...",
              style: Theme.of(context).textTheme.titleMedium),
        ),
        MoodSelector(
          onMoodSelected: (mood) =>
              ref.read(selectedMoodProvider.notifier).state = mood,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

        Expanded(
          child: restaurantsAsync.when(
            data: (restaurants) {
              if (isNearMeToggled) {
                final userLocationAsync = ref.watch(userLocationProvider);
                return userLocationAsync.when(
                  data: (userPos) {
                    final sorted = _filterAndSort(restaurants, selectedMood, searchQuery, userPos);
                    return _buildList(sorted);
                  },
                  loading: () => _buildShimmer(),
                  error: (err, stack) => Center(child: Text(err.toString())),
                );
              } else {
                final filtered = _filterAndSort(restaurants, selectedMood, searchQuery, null);
                return _buildList(filtered);
              }
            },
            loading: () => _buildShimmer(),
            error: (err, _) => Center(child: Text('Could not load restaurants.\nPlease check your connection.', textAlign: TextAlign.center)),
          ),
        ),
      ],
    );
  }

  List<Restaurant> _filterAndSort(List<Restaurant> restaurants, Mood? mood, String query, Position? userPosition) {
    List<Restaurant> filtered = restaurants.where((r) {
      final matchesMood = mood == null || r.cuisineTags.any((tag) => mood.associatedTags.contains(tag));
      final matchesSearch = query.isEmpty || r.name.toLowerCase().contains(query.toLowerCase());
      return matchesMood && matchesSearch;
    }).toList();

    if (userPosition != null) {
      filtered.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, a.location.latitude, a.location.longitude);
        final distanceB = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, b.location.latitude, b.location.longitude);
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  Widget _buildList(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(child: Text('No restaurants match your filters.'));
    }
    return ListView.builder(
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(restaurant: restaurant)));
          },
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(itemCount: 5, itemBuilder: (_, __) => const SkeletonCard()),
    );
  }
}
