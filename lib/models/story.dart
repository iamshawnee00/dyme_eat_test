// lib/models/story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryType { origin, ritual }

class Story {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String restaurantId;
  final StoryType type;
  final String status; // 'pending', 'approved'
  final Timestamp createdAt;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.restaurantId,
    required this.type,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Story.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Story(
      id: snapshot.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      type: StoryType.values.byName(data['type'] ?? 'ritual'),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'restaurantId': restaurantId,
      'type': type.name,
      'status': status,
      'createdAt': createdAt,
    };
  }
}