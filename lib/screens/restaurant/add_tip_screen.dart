// lib/screens/restaurant/add_tip_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTipScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const AddTipScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<AddTipScreen> createState() => _AddTipScreenState();
}

class _AddTipScreenState extends ConsumerState<AddTipScreen> {
  final _tipController = TextEditingController();
  TipType _selectedTipType = TipType.general;
  bool _isLoading = false;

  Future<void> _submitTip() async {
    final user = ref.read(authServiceProvider).currentUser;

    if (user == null || _tipController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip content cannot be empty.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final newTip = PathfinderTip(
      id: '', // Will be set by Firestore
      authorId: user.uid,
      restaurantId: widget.restaurantId,
      tipType: _selectedTipType,
      tipContent: _tipController.text,
      timestamp: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('pathfinderTips').add(newTip.toFirestore());
      
      // FIX: Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip submitted! Verification pending.')),
      );
      Navigator.pop(context);

    } catch (e) {
      // FIX: Guard against using BuildContext across async gaps.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit tip: $e')),
      );
    } finally {
      // FIX: Guard against using BuildContext across async gaps.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Pathfinder Tip')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<TipType>(
                    value: _selectedTipType,
                    items: TipType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.name.substring(0, 1).toUpperCase() + type.name.substring(1)),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedTipType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Tip Category', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tipController,
                    decoration: const InputDecoration(labelText: 'Your Tip', hintText: 'e.g., Park behind the building after 6 PM', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitTip,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Submit Tip'),
                  )
                ],
              ),
            ),
    );
  }
}
