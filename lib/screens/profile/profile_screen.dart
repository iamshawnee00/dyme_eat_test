// lib/screens/profile/profile_screen.dart
import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/profile/foodie_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the auth service to handle sign-out
    final authService = ref.read(authServiceProvider);
    // Watch the userProvider to get real-time updates for the current user
    final userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async => authService.signOut(),
          )
        ],
      ),
      // Use the .when method to handle loading and error states gracefully
      body: userAsyncValue.when(
        data: (appUser) {
          // If the user data is null (shouldn't happen if logged in), show an error.
          if (appUser == null) {
            return const Center(child: Text("User not found."));
          }
          // If we have user data, build the profile body.
          return _buildProfileBody(context, appUser);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text("Could not load profile.")),
      ),
    );
  }

  // This helper widget builds the main content of the profile screen.
  Widget _buildProfileBody(BuildContext context, AppUser appUser) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Profile Header ---
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                appUser.displayName ?? 'Foodie',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                appUser.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // =================================================================
        // THIS IS WHERE YOU SHOULD INPUT THE BUTTON
        // It's placed logically after the main profile header and before
        // the detailed "Trophy Case" section.
        // =================================================================
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: const Text("View My Foodie Card"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodieCardScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        
        // --- The "Trophy Case" Section ---
        _buildTrophyCase(context, appUser),
      ],
    );
  }

  // This helper widget builds the "Trophy Case" part of the profile.
  Widget _buildTrophyCase(BuildContext context, AppUser appUser) {
    final foodieCrest = appUser.foodiePersonality ?? "Not Yet Revealed";
    final influencePoints = appUser.influencePoints;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Legacy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Foodie Crest', foodieCrest, isCrest: appUser.foodieCrestRevealed),
                  _buildStatColumn('Influence', '$influencePoints IP'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This helper builds a single statistic for the trophy case.
  Widget _buildStatColumn(String title, String value, {bool isCrest = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isCrest ? Colors.blue.shade700 : null,
          ),
        ),
      ],
    );
  }
}

