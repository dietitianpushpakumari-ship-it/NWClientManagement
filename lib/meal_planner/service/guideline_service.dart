// lib/services/guideline_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/meal_planner/models/guidelines.dart';


/// Service class for managing Guideline master data in Firestore.
class GuidelineService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('guidelines');

  // --- READ ---
  /// Provides a stream of all *active* guidelines, ordered by title.
  Stream<List<Guideline>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('enTitle')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Guideline.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE ---
  Future<void> save(Guideline guideline) async {
    final Map<String, dynamic> data = guideline.toMap();

    if (guideline.id.isEmpty) {
      // Create
      await _collection.add(data);
    } else {
      // Update
      await _collection.doc(guideline.id).update(data);
    }
  }

  // --- DELETE (Soft Delete) ---
  Future<void> softDelete(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}