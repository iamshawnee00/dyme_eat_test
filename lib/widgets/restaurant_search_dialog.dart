// ignore: unused_import
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/providers/restaurant_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A stateful consumer widget to manage the search query within the dialog
class RestaurantSearchDialog extends ConsumerStatefulWidget {
  const RestaurantSearchDialog({super.key});

  @override
  ConsumerState<RestaurantSearchDialog> createState() => _RestaurantSearchDialogState();
}

class _RestaurantSearchDialogState extends ConsumerState<RestaurantSearchDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Watch the search provider with the current query
    final searchResultsAsync = ref.watch(searchRestaurantsProvider(_searchQuery));

    return AlertDialog(
      title: const Text("Search for a Restaurant"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Start typing restaurant name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: searchResultsAsync.when(
                data: (restaurants) {
                  if (restaurants.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(child: Text("No results found."));
                  }
                  return ListView.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return ListTile(
                        title: Text(restaurant.name),
                        onTap: () {
                          // When a restaurant is tapped, close the dialog and
                          // return the selected restaurant object.
                          Navigator.of(context).pop(restaurant);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Text("Error searching.")),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
      ],
    );
  }
}
