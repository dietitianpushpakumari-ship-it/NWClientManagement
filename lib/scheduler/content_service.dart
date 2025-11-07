// lib/services/content_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';

class ContentService {
  final CollectionReference _contentCollection =
  FirebaseFirestore.instance.collection('dietitian_content');

  // --- CREATE / UPDATE ---
  Future<void> saveContent(DietitianContentModel content) async {
    final data = content.toMap();
    if (content.id.isEmpty) {
      // Create
      await _contentCollection.add(data);
    } else {
      // Update
      await _contentCollection.doc(content.id).update(data);
    }
  }

  // --- DELETE ---
  Future<void> deleteContent(String id) {
    return _contentCollection.doc(id).delete();
  }

  // --- READ (Stream all content for Admin Library) ---
  Stream<List<DietitianContentModel>> streamAllContent() {
    return _contentCollection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DietitianContentModel.fromFirestore(doc))
          .toList();
    });
  }

  // --- READ (Stream for Client App, filtered by tags) ---
  Stream<List<DietitianContentModel>> streamContentByDisease(DiseaseTag tag) {
    // Queries where the 'diseaseTags' array field contains the specific tag name
    return _contentCollection
        .where('diseaseTags', arrayContains: tag.name)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DietitianContentModel.fromFirestore(doc))
          .toList();
    });
  }
}