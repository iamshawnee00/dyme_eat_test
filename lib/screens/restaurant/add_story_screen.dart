// lib/screens/restaurant/add_story_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/story.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddStoryScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const AddStoryScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends ConsumerState<AddStoryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  StoryType _selectedType = StoryType.ritual;
  bool _isLoading = false;

  Future<void> _submitStory() async {
    // It's good practice to read from the ref before an async gap
    final user = ref.read(authServiceProvider).currentUser;
    
    if (user == null || _titleController.text.isEmpty || _contentController.text.isEmpty) {
      // This is synchronous, but checking `mounted` is still a good habit for robustness.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content cannot be empty.')));
      }
      return;
    }

    setState(() => _isLoading = true);

    final newStory = Story(
      id: '', // Firestore will generate
      title: _titleController.text,
      content: _contentController.text,
      authorId: user.uid,
      restaurantId: widget.restaurantId,
      type: _selectedType,
      createdAt: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('stories').add(newStory.toFirestore());
      
      // FIX: Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story submitted for approval. Thank you!')),
      );
      Navigator.pop(context);

    } catch (e) {
      // FIX: Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      // The `mounted` check here is also crucial.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share a Story or Ritual')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                DropdownButtonFormField<StoryType>(
                  value: _selectedType,
                  items: StoryType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.substring(0, 1).toUpperCase() + type.name.substring(1)),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Your Story', alignLabelWithHint: true, border: OutlineInputBorder()),
                  maxLines: 8,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                    onPressed: _submitStory,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Submit for Approval')
                ),
              ],
            ),
    );
  }
}
