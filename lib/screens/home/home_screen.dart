import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/utils/mbti_characters.dart';
import 'package:dyme_eat/widgets/featured_restaurant_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// New provider to call our MBTI recommendation function
final mbtiRecommendationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // First, ensure we have a user with a personality
  final user = ref.watch(userProvider).asData?.value;
  if (user?.foodiePersonality == null) return [];

  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getMbtiRecommendations');
  final result = await callable.call();
  return List<Map<String, dynamic>>.from(result.data['recommendations']);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingRestaurantsProvider);
    final newAsync = ref.watch(newRestaurantsProvider);
    final mbtiAsync = ref.watch(mbtiRecommendationsProvider); // Watch our new provider
    final user = ref.watch(userProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Dyme Eat')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingRestaurantsProvider);
          ref.invalidate(newRestaurantsProvider);
          ref.invalidate(mbtiRecommendationsProvider);
        },
        child: ListView(
          children: [
            // --- NEW: Personalized MBTI Recommendations Section ---
            if (user?.foodiePersonality != null)
              mbtiAsync.when(
                data: (restaurants) {
                  if (restaurants.isEmpty) return const SizedBox.shrink();
                  final character = foodieCharacters[user!.foodiePersonality] ?? foodieCharacters['default']!;
                  return FeaturedRestaurantList(
                    title: "Dicadangkan untuk ${character.name}",
                    restaurants: restaurants.map((r) => Restaurant.fromMap(r)).toList(),
                  );
                },
                loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              ),

            // --- Existing Sections ---
            trendingAsync.when(
              data: (restaurants) => restaurants.isEmpty 
                  ? const SizedBox.shrink()
                  : FeaturedRestaurantList(
                      title: "Trending Restaurants",
                      restaurants: restaurants,
                    ),
              loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
            ),
            newAsync.when(
              data: (restaurants) => restaurants.isEmpty
                  ? const SizedBox.shrink()
                  : FeaturedRestaurantList(
                      title: "Recently Added",
                      restaurants: restaurants,
                    ),
              loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
