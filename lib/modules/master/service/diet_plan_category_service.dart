// lib/services/diet_plan_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/diet_plan_category.dart';

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

  Future<List<DietPlanCategory>> fetchAllActiveCategories() async{
    try {

      QuerySnapshot<Object?> snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .orderBy('enName')
          .get(); // 🎯 Key change: .get() instead of .snapshots()

      // 2. Map the QuerySnapshot documents to a List<FoodItem>
      return snapshot.docs
          .map((doc) => DietPlanCategory.fromFirestore(doc))
          .toList();

    } catch (e) {
      // Handle errors (e.g., logging, throwing a more specific exception)
      print('Error fetching food items from Firebase: $e');
      // Return an empty list on failure to prevent the app from crashing
      return [];
    }
  }
}