import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/widgets/featured_restaurant_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingRestaurantsProvider);
    final newAsync = ref.watch(newRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyme Eat'),
      ),
      body: ListView(
        children: [
          // Trending Restaurants Section
          trendingAsync.when(
            data: (restaurants) => FeaturedRestaurantList(
              title: "Trending Restaurants",
              restaurants: restaurants,
            ),
            loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
            error: (err, stack) => const SizedBox.shrink(), // Don't show anything on error
          ),
          
          // New Restaurants Section
          newAsync.when(
            data: (restaurants) => FeaturedRestaurantList(
              title: "Recently Added",
              restaurants: restaurants,
            ),
            loading: () => const Center(heightFactor: 10, child: CircularProgressIndicator()),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
