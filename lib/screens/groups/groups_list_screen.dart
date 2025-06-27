import 'package:flutter/material.dart';

// This is a placeholder screen for the Groups feature.
// We will build this out in a future phase.
class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groups'),
      ),
      body: const Center(
        child: Text(
          'Group features coming soon!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}