import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedContentType {
  video, // 🎯 Changed from youtubeVideo to generic 'video' (stores link)
  imagePost,
  articleLink,
  recipe,
  advertisement,
  socialPost,
  article
}

class FeedContentModel {
  final String id;
  final String title;
  final String description;
  final FeedContentType type;

  // --- Content Specifics ---
  final String? mediaUrl;      // Stores Image URL (Upload) OR Video Link (Text)
  final String? actionUrl;     // External link (e.g. "Read More")
  final String? callToAction;

  final Map<String, dynamic>? recipeData;
  final List<String> targetTags;
  final bool isPublished;
  final int views;
  final int shares;
  final DateTime createdAt;

  FeedContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.mediaUrl,
    this.actionUrl,
    this.callToAction,
    this.recipeData,
    this.targetTags = const [],
    this.isPublished = true,
    this.views = 0,
    this.shares = 0,
    required this.createdAt,
  });

  factory FeedContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedContentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: FeedContentType.values.firstWhere(
              (e) => e.name == (data['type'] ?? 'imagePost'),
          orElse: () => FeedContentType.imagePost),
      mediaUrl: data['mediaUrl'],
      actionUrl: data['actionUrl'],
      callToAction: data['callToAction'],
      recipeData: data['recipeData'],
      targetTags: List<String>.from(data['targetTags'] ?? []),
      isPublished: data['isPublished'] ?? true,
      views: data['views'] ?? 0,
      shares: data['shares'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'actionUrl': actionUrl,
      'callToAction': callToAction,
      'recipeData': recipeData,
      'targetTags': targetTags,
      'isPublished': isPublished,
      'views': views,
      'shares': shares,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}