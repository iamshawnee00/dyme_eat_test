import 'package:cloud_functions/cloud_functions.dart';
//import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert to a ConsumerStatefulWidget to handle loading state for the recommendation button
class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool _isRecommending = false;

  void _getRecommendation() async {
    setState(() => _isRecommending = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getGroupRecommendation');
      final result = await callable.call(<String, dynamic>{'groupId': widget.group.id});
      final recommendation = result.data['recommendation'];
      
      if(mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(recommendation['name']),
            content: Text("Suggestion: ${recommendation['reason']}\n\nAddress: ${recommendation['address']}"),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if(mounted) setState(() => _isRecommending = false);
    }
  }
  
  // ... _showAddMemberDialog remains the same ...
  void _showAddMemberDialog(BuildContext context) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider(widget.group.members));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: "Add Member",
            onPressed: () => _showAddMemberDialog(context),
          )
        ],
      ),
      body: Column(
        children: [
          // Recommendation Button Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isRecommending
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.recommend_outlined),
                    label: const Text("Get AI Recommendation"),
                    onPressed: _getRecommendation,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
          ),
          const Divider(height: 1),
          // Member List Section
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) return const Center(child: Text("This group has no members."));
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
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
          ),
        ],
      ),
    );
  }
}
