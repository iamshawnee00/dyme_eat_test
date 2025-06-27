import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/app_user.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to get real-time data for the currently logged-in user.
final userProvider = StreamProvider<AppUser?>((ref) {
  // First, watch the authentication state.
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;

  // If the user is not logged in, return a stream with null.
  if (user == null) {
    return Stream.value(null);
  }

  // If the user is logged in, listen to their document in the 'users' collection.
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        // If the document exists, convert it to an AppUser object.
        if (snapshot.exists) {
            return AppUser.fromFirestore(snapshot, null);
        }
        // If the document doesn't exist (e.g., just after sign-up, before creation), return null.
        return null;
      });
});


// A new provider that fetches the user profiles for a given list of member IDs.
final groupMembersProvider = FutureProvider.autoDispose.family<List<AppUser>, List<String>>((ref, memberIds) async {
  if (memberIds.isEmpty) {
    return [];
  }
  final firestore = FirebaseFirestore.instance;
  // Fetch all user documents where the UID is in our list of memberIds.
  final querySnapshot = await firestore
      .collection('users')
      .where(FieldPath.documentId, whereIn: memberIds)
      .get();
  
  // Convert the documents to AppUser objects.
  return querySnapshot.docs.map((doc) => AppUser.fromFirestore(doc, null)).toList();
});