import 'package:cloud_functions/cloud_functions.dart';
// ignore: unused_import
import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert the widget to a ConsumerWidget to use Riverpod
class GroupDetailScreen extends ConsumerWidget {
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member added!")));
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new provider to get the profiles of the group members
    final membersAsync = ref.watch(groupMembersProvider(group.members));

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
      // Use .when to handle loading/error states for the member list
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text("This group has no members."));
          }
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  // Display the user's photo, or a placeholder icon
                  backgroundImage: member.photoURL != null ? NetworkImage(member.photoURL!) : null,
                  child: member.photoURL == null ? const Icon(Icons.person_outline) : null,
                ),
                title: Text(member.displayName ?? "Unknown User"),
                subtitle: Text(member.email ?? "No email"),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text("Could not load member profiles.")),
      ),
    );
  }
}
