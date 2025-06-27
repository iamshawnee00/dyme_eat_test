import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/group.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    return Stream.value([]);
  }

  // Listen to the 'groups' collection for any group where the current user's ID
  // is present in the 'members' array.
  return FirebaseFirestore.instance
      .collection('groups')
      .where('members', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
});
