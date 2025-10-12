// lib/services/food_item_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';

/// Service class for managing FoodItem master data in Firestore.
class FoodItemService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('foodItems');

  // --- READ ---
  Stream<List<FoodItem>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FoodItem.fromFirestore(doc))
        .toList());
  }

  // --- READ by Category (Useful for filtering) ---
  Stream<List<FoodItem>> streamByCategory(String categoryId) {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('enName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FoodItem.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE ---
  Future<void> save(FoodItem item) async {
    final Map<String, dynamic> data = item.toMap();

    if (item.id.isEmpty) {
      // Create
      await _collection.add(data);
    } else {
      // Update
      await _collection.doc(item.id).update(data);
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