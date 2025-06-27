// lib/screens/profile/profile_screen.dart
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    
    // In a real scenario, you would fetch user data from Firestore
    // For now, we use placeholder data.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Profile Header ---
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  // Placeholder for user photo
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  authService.currentUser?.displayName ?? 'Foodie',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  authService.currentUser?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // --- The Trophy Case Section ---
          _buildTrophyCase(context),
        ],
      ),
    );
  }

  Widget _buildTrophyCase(BuildContext context) {
    // These are placeholders as per the first milestone
    const foodieCrest = "TBD"; // To be replaced with a beautiful crest visual
    const influencePoints = 0; // To be fetched from user data

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Legacy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Foodie Crest', foodieCrest),
                  _buildStatColumn('Influence', '$influencePoints IP'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder for "Legacy" credits (e.g., Discoverer of Rituals)
          const ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('No legacy credits earned yet.'),
            subtitle: Text('Contribute stories to earn them!'),
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
