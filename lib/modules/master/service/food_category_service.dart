// lib/services/food_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import '../../../master/model/food_category.dart';

/// Service class for managing FoodCategory master data in Firestore.
class FoodCategoryService {

  final Ref _ref; // Store Ref to access dynamic providers
  FoodCategoryService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection('foodCategories');

  // --- READ ---
  /// Provides a stream of all *active* food categories, ordered by displayOrder.
  Stream<List<FoodCategory>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('displayOrder') // Use displayOrder for custom sorting
        .orderBy('enName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FoodCategory.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE ---
  Future<void> save(FoodCategory category) async {
    final Map<String, dynamic> data = category.toMap();

    if (category.id.isEmpty) {
      // Create: Firestore generates ID
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