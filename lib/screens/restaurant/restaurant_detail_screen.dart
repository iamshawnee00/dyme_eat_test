import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/models/story.dart';
import 'package:dyme_eat/screens/restaurant/add_story_screen.dart';
import 'package:dyme_eat/screens/restaurant/add_tip_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

// Provider to get real-time updates for the restaurant document
final restaurantStreamProvider = StreamProvider.autoDispose.family<Restaurant, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .snapshots()
      .map((doc) => Restaurant.fromFirestore(doc));
});

// Provider to get pathfinder tips for the restaurant
final tipsStreamProvider = StreamProvider.autoDispose.family<List<PathfinderTip>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('pathfinderTips')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PathfinderTip.fromFirestore(doc)).toList());
});

// Provider to get approved stories for the restaurant
final storiesStreamProvider = StreamProvider.autoDispose.family<List<Story>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('stories')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList());
});

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantStreamProvider(restaurant.id));
    final tipsAsync = ref.watch(tipsStreamProvider(restaurant.id));
    final storiesAsync = ref.watch(storiesStreamProvider(restaurant.id));

    return Scaffold(
      // Use a custom scroll view to create a collapsing app bar effect with the photo gallery
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(restaurant.name, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 2.0)])),
              background: restaurantAsync.when(
                data: (r) => _buildPhotoGallery(context, r.imageUrls),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Icon(Icons.error)),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // --- Taste Signature Chart (Now in its own section) ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Taste Signature", style: Theme.of(context).textTheme.headlineSmall),
                      const Divider(),
                      SizedBox(
                        height: 250,
                        child: restaurantAsync.when(
                          data: (r) => _buildTasteSignatureChart(context, r.overallTasteSignature),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => const Center(child: Text("Can't load taste data")),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Pathfinder Tips Section ---
                      _buildSectionHeader(context, "Pathfinder Tips", Icons.add_circle_outline, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddTipScreen(restaurantId: restaurant.id)));
                      }),
                      const Divider(),
                      tipsAsync.when(
                        data: (tips) => _buildTipsList(tips),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(child: Text("Could not load tips.")),
                      ),
                      const SizedBox(height: 24),

                      // --- Stories & Rituals Section ---
                      _buildSectionHeader(context, "Stories & Rituals", Icons.history_edu_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddStoryScreen(restaurantId: restaurant.id)));
                      }),
                      const Divider(),
                      storiesAsync.when(
                        data: (stories) => _buildStoriesList(stories),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Center(child: Text("Could not load stories.")),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for building UI sections ---

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: "Add ${title.split(' ').first}"),
      ],
    );
  }

  Widget _buildTipsList(List<PathfinderTip> tips) {
    if (tips.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Be the first to leave a tip!")));
    return Column(
      children: tips.map((tip) => ListTile(
        leading: Icon(tip.isVerified ? Icons.verified_user : Icons.lightbulb_outline, color: tip.isVerified ? Colors.blue : Colors.grey),
        title: Text(tip.tipContent),
        subtitle: Text("shared ${timeago.format(tip.timestamp.toDate())}"),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(tip.upvotes.toString()), const SizedBox(width: 4), const Icon(Icons.thumb_up_alt_outlined, size: 16)]),
      )).toList(),
    );
  }

  Widget _buildStoriesList(List<Story> stories) {
    if (stories.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Be the first to share a story!")));
    return Column(
      children: stories.map((story) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(story.content, maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      )).toList(),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, List<String> imageUrls) {
    if (imageUrls.isEmpty) return Container(color: Colors.grey.shade400, child: const Center(child: Icon(Icons.camera_alt, size: 60, color: Colors.white70)));

    return PageView.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.white70)),
        );
      },
    );
  }

  Widget _buildTasteSignatureChart(BuildContext context, Map<String, dynamic> signatureData) {
    final mutableSignature = Map<String, dynamic>.from(signatureData);
    mutableSignature.removeWhere((key, value) => key == '_reviewCount');
    if (mutableSignature.isEmpty) return const Center(child: Text("No reviews yet. Be the first!"));
    final tasteKeys = mutableSignature.keys.toList();
    final dataValues = tasteKeys.map((key) => mutableSignature[key] as double).toList();

    return RadarChart(
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
        getTitle: (index, angle) => RadarChartTitle(text: tasteKeys[index], angle: angle),
        tickCount: 5,
      ),
    );
  }
}