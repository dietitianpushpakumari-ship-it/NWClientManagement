// lib/models/dietitian_content_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';

class DietitianContentModel {
  final String id;
  final ContentType postType;
  final String title;
  final String content; // Markdown text
  final String? imageUrl;
  final List<DiseaseTag> diseaseTags; // New field for filtering
  final List<String> generalTags;
  final DateTime publishedAt;
  final DateTime? updatedAt;

  DietitianContentModel({
    required this.id,
    required this.postType,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.diseaseTags,
    required this.generalTags,
    required this.publishedAt,
    this.updatedAt,
  });

  factory DietitianContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietitianContentModel(
      id: doc.id,
      postType: ContentType.fromName(data['postType'] ?? 'healthyTip'),
      title: data['title'] ?? 'Untitled Content',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      diseaseTags: (data['diseaseTags'] as List<dynamic>?)
          ?.map((name) => DiseaseTag.fromName(name as String))
          .toList() ??
          [DiseaseTag.general],
      generalTags: List<String>.from(data['generalTags'] ?? []),
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'postType': postType.name,
      'content': content,
      'imageUrl': imageUrl,
      'diseaseTags': diseaseTags.map((e) => e.name).toList(),
      'generalTags': generalTags,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}