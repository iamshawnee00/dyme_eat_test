import 'package:cloud_functions/cloud_functions.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  void _showAddMemberDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Member"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter user's email"),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty) return;
                try {
                  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('addMemberToGroup');
                  await callable.call(<String, dynamic>{
                    'groupId': group.id,
                    'newUserEmail': emailController.text.trim(),
                  });
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member added! (Refresh to see update)")));
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if(context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: "Add Member",
            onPressed: () => _showAddMemberDialog(context),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: group.members.length,
        itemBuilder: (context, index) {
          final memberId = group.members[index];
          // In a real app, you would use this ID to fetch the member's full profile
          return ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text("User ID: ${memberId.substring(0, 8)}..."), // Show a snippet of the ID
          );
        },
      ),
    );
  }
}
