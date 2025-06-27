import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
  });

  factory Group.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Group(
      id: snapshot.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }
}