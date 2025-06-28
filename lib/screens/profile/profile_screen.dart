import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/profile/foodie_card_screen.dart';
import 'package:dyme_eat/utils/mbti_characters.dart'; // <-- Import our new characters
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: userAsyncValue.when(
        data: (appUser) {
          if (appUser == null) {
            return const Center(child: Text("User profile not found."));
          }
          return _buildProfileBody(context, appUser, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text("Could not load profile.")),
      ),
    );
  }

  // This consolidated helper widget builds the entire profile screen body.
  Widget _buildProfileBody(BuildContext context, AppUser appUser, WidgetRef ref) {
    // Get the character details from our map using the user's personality code
    final character = foodieCharacters[appUser.foodiePersonality] ?? foodieCharacters['default']!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- NEW: MBTI Character Card ---
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(character.icon, size: 50, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(character.name, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(character.description, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        

        // --- Foodie Card Button ---
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: const Text("View My Foodie Card"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16)
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodieCardScreen()));
          },
        ),

        // --- User Stats / Trophy Case ---
        const SizedBox(height: 24),
        const Divider(),
        _buildTrophyCase(context, appUser),     
      ],
    );
  }
  
  // This helper widget builds the "Trophy Case" part of the profile.
  Widget _buildTrophyCase(BuildContext context, AppUser appUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Influence', '${appUser.influencePoints} IP'),
            _buildStatColumn('Reviews', '0'), // Placeholder, can be implemented later
            _buildStatColumn('Crest', appUser.foodiePersonality ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // This helper builds a single statistic for the trophy case.
  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
