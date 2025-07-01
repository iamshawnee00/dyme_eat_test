import 'package:flutter/material.dart';

// This widget represents the placeholder layout for a restaurant card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0, // No shadow for a skeleton
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton for the title
            Container(width: 200, height: 24, color: Colors.black),
            const SizedBox(height: 12),
            // Skeleton for the address line
            Container(width: double.infinity, height: 16, color: Colors.black),
            const SizedBox(height: 16),
            // Skeleton for the tags
            Wrap(
              spacing: 8.0,
              children: [
                Container(width: 80, height: 30, color: Colors.black),
                Container(width: 100, height: 30, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
