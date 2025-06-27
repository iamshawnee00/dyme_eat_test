// lib/screens/contribute/add_review_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/models/review.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const AddReviewScreen({super.key, required this.restaurant});

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  // Hardcoded for now. This would be dynamically loaded based on dish type.
  final Map<String, double> _tasteDialData = {
    'Wok Hei': 3.0,
    'Spiciness': 3.0,
    'Sweetness': 3.0,
    'Richness': 3.0,
  };
  bool _isLoading = false;

  Future<void> _submitReview() async {
    // Read the user from the provider before the async gap.
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      // Check if the widget is still in the tree before using its context.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a review.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final newReview = Review(
      authorId: user.uid,
      restaurantId: widget.restaurant.id,
      timestamp: Timestamp.now(),
      tasteDialData: _tasteDialData,
    );

    try {
      await FirebaseFirestore.instance.collection('reviews').add(newReview.toFirestore());
      
      // Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted! +25 IP awarded!')),
      );
      Navigator.pop(context);

    } catch (e) {
      // Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${widget.restaurant.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'The Taste Dial',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Rate the distinct flavors of your experience.'),
                const SizedBox(height: 24),
                // Removed the unnecessary .toList() call.
                ..._tasteDialData.keys.map((tasteName) {
                  return _buildSlider(tasteName);
                }),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // Moved the child argument to the end.
                  child: const Text('Submit Taste Profile'),
                )
              ],
            ),
    );
  }

  Widget _buildSlider(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_tasteDialData[name]!.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: _tasteDialData[name]!,
          min: 0,
          max: 5,
          divisions: 10,
          label: _tasteDialData[name]!.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _tasteDialData[name] = value;
            });
          },
        ),
      ],
    );
  }
}

