// lib/screens/restaurant/restaurant_detail_screen.dart
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/models/story.dart';
import 'package:dyme_eat/models/review.dart'; // <-- Add this import
import 'package:dyme_eat/screens/restaurant/add_story_screen.dart';
import 'package:dyme_eat/screens/restaurant/add_tip_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

final tipsStreamProvider = StreamProvider.autoDispose.family<List<PathfinderTip>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('pathfinderTips')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PathfinderTip.fromFirestore(doc)).toList());
});

// << NEW PROVIDER FOR REVIEWS >>
final reviewsStreamProvider = StreamProvider.autoDispose.family<List<Review>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
    .collection('reviews')
    .where('restaurantId', isEqualTo: restaurantId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc.data())).toList());
});

// << NEW PROVIDER FOR STORIES >>
final storiesStreamProvider = StreamProvider.autoDispose.family<List<Story>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('stories')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', isEqualTo: 'approved') // Only show approved stories
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList());
});

// << NEW PROVIDER FOR REAL-TIME RESTAURANT UPDATES >>
final restaurantStreamProvider = StreamProvider.autoDispose.family<Restaurant, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .snapshots()
      .map((doc) => Restaurant.fromFirestore(doc));
});

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(tipsStreamProvider(restaurant.id));
    final restaurantAsync = ref.watch(restaurantStreamProvider(restaurant.id)); // << CORRECTED
    final storiesAsync = ref.watch(storiesStreamProvider(restaurant.id)); // << WATCH STORIES

    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Placeholder for Taste Signature visualization
          Card(
            child: SizedBox(
              height: 250, //Give the chart some space
              child: restaurantAsync.when(
                data: (updatedRestaurant) => _buildTasteSignatureChart(context, updatedRestaurant.overallTasteSignature),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text("Can't load taste data")),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Pathfinder Tips Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pathfinder Tips", style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddTipScreen(restaurantId: restaurant.id)));
                },
              ),
            ],
          ),
          const Divider(),
          tipsAsync.when(
            data: (tips) {
              if (tips.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Be the first to leave a tip!"),
                ));
              }
              return Column(
                children: tips.map((tip) => ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(tip.tipContent),
                  subtitle: Text("shared ${timeago.format(tip.timestamp.toDate())}"),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text("Could not load tips.")),
          ),

          // << NEW STORIES & RITUALS SECTION >>
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Stories & Rituals", style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.history_edu_outlined),
                tooltip: "Share a Story",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddStoryScreen(restaurantId: restaurant.id)));
                },
              ),
            ],
          ),
          const Divider(),
          storiesAsync.when(
            data: (stories) {
              if (stories.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Be the first to share a story or ritual!"),
                ));
              }
              return Column(
                children: stories.map((story) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(story.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text("Could not load stories.")),
          ),
        ],
      ),
    );
  }

  // << WIDGET IS NOW SIMPLER AND CORRECT >>
  Widget _buildTasteSignatureChart(BuildContext context, Map<String, dynamic> signatureData) {
    final mutableSignature = Map<String, dynamic>.from(signatureData);
    mutableSignature.removeWhere((key, value) => key == '_reviewCount');
    
    if (mutableSignature.isEmpty) {
      return const Center(child: Text("No reviews yet. Be the first!"));
    }

    final tasteKeys = mutableSignature.keys.toList();
    final dataValues = tasteKeys.map((key) => mutableSignature[key] as double).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: dataValues.map((value) => RadarEntry(value: value)).toList(),
              borderColor: Theme.of(context).colorScheme.primary,
              fillColor: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.grey, width: 2),
          tickBorderData: const BorderSide(color: Colors.grey, width: 1),
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          getTitle: (index, angle) {
              return RadarChartTitle(text: tasteKeys[index], angle: angle);
          },
          tickCount: 5,
         
        ),
      ),
    );
  }
}
