import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:dyme_eat/models/restaurant.dart';
// ignore: unused_import
import 'package:dyme_eat/providers/group_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/groups/chat_screen.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart';
import 'package:dyme_eat/widgets/restaurant_card.dart';
import 'package:dyme_eat/widgets/restaurant_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Provider to call our advanced recommendation function
final groupRecommendationsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getGroupRecommendations');
  final result = await callable.call(<String, dynamic>{'groupId': groupId});
  return List<Map<String, dynamic>>.from(result.data['recommendations']);
});

class GroupDetailScreen extends ConsumerWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  // Helper method to launch the "Rate a Place" flow
  void _showRatePlaceFlow(BuildContext context, WidgetRef ref) async {
    final Restaurant? selectedRestaurant = await showDialog<Restaurant>(
      context: context,
      builder: (context) => const RestaurantSearchDialog(),
    );

    if (selectedRestaurant != null && context.mounted) {
      _showRatingDialog(context, ref, selectedRestaurant);
    }
  }

  // Helper method to show the final rating dialog
  void _showRatingDialog(BuildContext context, WidgetRef ref, Restaurant restaurant) {
    int rating = 3; // Default rating
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Rate ${restaurant.name}"),
          content: const Text("How would you rate this place for the group? (1-5)"), // Placeholder for a star rating widget
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final callable = FirebaseFunctions.instance.httpsCallable('rateRestaurantForGroup');
                  await callable.call({'groupId': group.id, 'restaurantId': restaurant.id, 'rating': rating});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rating submitted! Group preferences updated.")));
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                  }
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
          // --- Section 1: Top 5 Recommendations ---
          _buildSliverHeader(context, "Top 5 Port Pilihan"),
          recommendationsAsync.when(
            data: (recs) => SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                  final tempRestaurant = Restaurant.fromMap(recs[index]);
                  return RestaurantCard(
                    restaurant: tempRestaurant,
                    onTap: () async {
                      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(tempRestaurant.id).get();
                      if (context.mounted) {
                        final fullRestaurant = Restaurant.fromFirestore(doc);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: fullRestaurant)));
                      }
                    }
                  );
                }, childCount: recs.length),
            ),
            loading: () => _buildSliverLoadingIndicator(),
            error: (e,s) => _buildSliverError(e.toString()),
          ),

          // --- Section 2: Group Chat Button ---
           SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Open Group Chat"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(groupId: group.id, groupName: group.name)));
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ),
          ),

          // --- Section 3: Members & Preferences ---
          _buildSliverHeader(context, "Members & Preferences"),
          membersAsync.when(
            data: (members) => SliverList(
              delegate: SliverChildBuilderDelegate((context, index) => _buildMemberCard(context, members[index]), childCount: members.length),
            ),
            loading: () => _buildSliverLoadingIndicator(),
            error: (e,s) => _buildSliverError("Could not load members."),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRatePlaceFlow(context, ref),
        label: const Text("Rate a Place"),
        icon: const Icon(Icons.rate_review_outlined),
      ),
    );
  }

  // --- UI Helper Methods ---
  
  SliverToBoxAdapter _buildSliverHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }

  SliverToBoxAdapter _buildSliverLoadingIndicator() {
    return const SliverToBoxAdapter(child: Center(child: Padding(
      padding: EdgeInsets.all(32.0),
      child: CircularProgressIndicator(),
    )));
  }

  SliverToBoxAdapter _buildSliverError(String message) {
    return SliverToBoxAdapter(child: Center(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(message),
    )));
  }

  Widget _buildMemberCard(BuildContext context, AppUser member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: member.photoURL != null ? NetworkImage(member.photoURL!) : null,
                child: member.photoURL == null ? const Icon(Icons.person_outline) : null,
              ),
              title: Text(member.displayName ?? "Unknown User", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(member.email ?? "No email"),
            ),
            if (member.allergies.isNotEmpty || member.preferences.isNotEmpty)
              const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  if (member.allergies.isNotEmpty)
                    _buildInfoRow(context, Icons.warning_amber_rounded, "Allergies", member.allergies.join(', '), Colors.red.shade700),
                  if (member.preferences.isNotEmpty)
                    _buildInfoRow(context, Icons.restaurant_menu_outlined, "Preferences", member.preferences.join(', '), null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
