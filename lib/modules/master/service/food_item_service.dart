// lib/services/food_item_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import '../../../master/model/food_item.dart';

/// Service class for managing FoodItem master data in Firestore.
class FoodItemService {
  final Ref _ref; // Store Ref to access dynamic providers
  FoodItemService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_FoodItem));


  // --- READ ---
  Stream<List<FoodItem>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
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
        .orderBy('name')
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

  Future<List<FoodItem>> fetchAllActiveFoodItems() async{
    try {

      QuerySnapshot<Object?> snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .orderBy('name')
          .get(); // 🎯 Key change: .get() instead of .snapshots()

      // 2. Map the QuerySnapshot documents to a List<FoodItem>
      return snapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc))
          .toList();

    } catch (e) {
      // Handle errors (e.g., logging, throwing a more specific exception)
      print('Error fetching food items from Firebase: $e');
      // Return an empty list on failure to prevent the app from crashing
      return [];
    }
  }




}