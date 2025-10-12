// lib/services/diet_plan_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diet_plan_category.dart';

/// Service class for managing DietPlanCategory master data in Firestore.
class DietPlanCategoryService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('dietPlanCategories');

  // --- READ ---
  /// Provides a stream of all *active* diet plan categories.
  Stream<List<DietPlanCategory>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DietPlanCategory.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE ---
  Future<void> save(DietPlanCategory category) async {
    final Map<String, dynamic> data = category.toMap();

    if (category.id.isEmpty) {
      // Create
      await _collection.add(data);
    } else {
      // Update
      await _collection.doc(category.id).update(data);
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