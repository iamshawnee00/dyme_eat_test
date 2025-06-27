import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:dyme_eat/models/restaurant.dart';
// import 'package:dyme_eat/providers/group_provider.dart'; // <-- REMOVED: Unused import
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:dyme_eat/widgets/restaurant_card.dart';
import 'package:dyme_eat/widgets/restaurant_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dyme_eat/screens/groups/chat_screen.dart';

// New provider to call our advanced recommendation function
final groupRecommendationsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getGroupRecommendations');
  final result = await callable.call(<String, dynamic>{'groupId': groupId});
  return List<Map<String, dynamic>>.from(result.data['recommendations']);
});

class GroupDetailScreen extends ConsumerWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  // This method now launches our search dialog
  void _showRatePlaceFlow(BuildContext context, WidgetRef ref) async {
    final Restaurant? selectedRestaurant = await showDialog<Restaurant>(
      context: context,
      builder: (context) => const RestaurantSearchDialog(),
    );

    // FIX: Guard the context with a mounted check
    if (selectedRestaurant != null && context.mounted) {
      _showRatingDialog(context, ref, selectedRestaurant);
    }
  }

  // This new method shows the actual rating confirmation
  void _showRatingDialog(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    int rating = 3; // Default rating
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Rate ${restaurant.name}"),
          content: Text("How would you rate this place for the group? (1-5)"), // Placeholder for a star rating widget
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final callable = FirebaseFunctions.instance.httpsCallable('rateRestaurantForGroup');
                  await callable.call({
                    'groupId': group.id,
                    'restaurantId': restaurant.id,
                    'rating': rating,
                  });
                  // FIX: Guard the context with a mounted check
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rating submitted! Group preferences have been updated.")));
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  // Handle error
                }
              },
              child: const Text("Submit Rating"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.members));
    final recommendationsAsync = ref.watch(groupRecommendationsProvider(group.id));

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: CustomScrollView(
        slivers: [
          // --- Group Recommendations Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Top 5 Port Pilihan", style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          recommendationsAsync.when(
            data: (recs) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tempRestaurant = Restaurant(
                    id: recs[index]['id'],
                    name: recs[index]['name'],
                    address: recs[index]['address'],
                    imageUrls: List<String>.from(recs[index]['imageUrls']),
                    location: const GeoPoint(0,0),
                    cuisineTags: [], 
                    overallTasteSignature: {},
                  );
                  return RestaurantCard(
                    restaurant: tempRestaurant,
                    onTap: () async {
                      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(tempRestaurant.id).get();
                      final fullRestaurant = Restaurant.fromFirestore(doc);
                      // FIX: Guard the context with a mounted check
                      if(context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: fullRestaurant)));
                      }
                    }
                  );
                },
                childCount: recs.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))),
            error: (e,s) => SliverToBoxAdapter(child: Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(e.toString()),
            ))),
          ),

          // --- Members Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text("Members", style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          membersAsync.when(
            data: (members) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.photoURL != null ? NetworkImage(member.photoURL!) : null,
                      child: member.photoURL == null ? const Icon(Icons.person_outline) : null,
                    ),
                    title: Text(member.displayName ?? "Unknown User"),
                  );
                },
                childCount: members.length
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e,s) => SliverToBoxAdapter(child: Center(child: Text("Could not load members."))),
          ),
          // --- Chat Button Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Open Group Chat"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(groupId: group.id, groupName: group.name)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showRatePlaceFlow(context, ref);
        },
        label: const Text("Rate a Place"),
        icon: const Icon(Icons.rate_review_outlined),
      ),
    );
  }
}
