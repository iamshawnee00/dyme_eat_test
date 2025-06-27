// The 'unused_import' warning is suppressed because the type is needed by the provider.
// ignore: unused_import
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the restaurantListProvider to get the stream of restaurants
    final restaurantsAsyncValue = ref.watch(restaurantListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Restaurants'),
        // In a future step, a search icon button could be added here
      ),
      body: restaurantsAsyncValue.when(
        // The data is available, display it in a list
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return const Center(
              child: Text(
                'No restaurants found.\nTry suggesting one from the Contribute tab!',
                textAlign: TextAlign.center,
              ),
            );
          }
          // Display the list of restaurants using ListView.builder for efficiency
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return ListTile(
                title: Text(restaurant.name),
                subtitle: Text(restaurant.address),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the RestaurantDetailScreen when a restaurant is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                    ),
                  );
                },
              );
            },
          );
        },
        // A loading state is shown while the data is being fetched
        loading: () => const Center(child: CircularProgressIndicator()),
        // An error state is shown if fetching the data fails
        error: (error, stack) => Center(
          child: Text(
            'Could not load restaurants.\nPlease check your connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
