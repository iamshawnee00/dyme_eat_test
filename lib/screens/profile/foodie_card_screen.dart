import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Provider to call our backend function and fetch the card data
final foodieCardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateFoodieCardData');
  final result = await callable.call();
  return Map<String, dynamic>.from(result.data);
});

class FoodieCardScreen extends ConsumerWidget {
  const FoodieCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardDataAsync = ref.watch(foodieCardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Foodie Card')),
      body: Center(
        child: cardDataAsync.when(
          data: (data) => _buildCard(context, data),
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    final cardDataJson = jsonEncode(data); // Encode the data for the QR code
    // Get the character details from the user's MBTI
    final character = foodieCharacters[data['crest']] ?? foodieCharacters['default']!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header section with user info
                Column(
                  children: [
                    // MODIFIED: Display the character's icon
                  CircleAvatar(radius: 40, child: Icon(character.icon, size: 40)),
                  const SizedBox(height: 12),
                    Text(data['name'] ?? 'Foodie', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Crest: ${data['crest'] ?? 'N/A'}', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                    Text('${data['ip'] ?? 0} IP', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
                
                // QR Code in the middle
                QrImageView(
                  data: cardDataJson,
                  version: QrVersions.auto,
                  size: 150.0,
                ),

                // Footer section with top flavors
                Column(
                  children: [
                    const Text("Top Flavors", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text((data['topFlavors'] as List).join(', ')),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text("Add to Wallet (Coming Soon)"),
                      onPressed: null, // Disabled for now, to be implemented later
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
