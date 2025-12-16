// lib/services/master_meal_name_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';


/// Service class for managing MasterMealName data in Firestore.
class MasterMealNameService {
  final Ref _ref; // Store Ref to access dynamic providers
  MasterMealNameService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_MealNames));


  // --- READ ---
  /// Provides a stream of all *active* meal names, ordered by English name.
  Stream<List<MasterMealName>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MasterMealName.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE ---
  Future<void> save(MasterMealName mealName) async {
    final Map<String, dynamic> data = mealName.toMap();

    if (mealName.id.isEmpty) {
      // Create: Add a new document
      await _collection.add(data);
    } else {
      // Update: Update existing document
      await _collection.doc(mealName.id).update(data);
    }
  }

  // --- DELETE (Soft Delete) ---
  Future<void> softDelete(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }


  Future<List<MasterMealName>> fetchAllMealNames() async {
    try {
      QuerySnapshot<Object?> snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .orderBy('order')
          .get(); // 🎯 Key change: .get() instead of .snapshots()

      // 2. Map the QuerySnapshot documents to a List<FoodItem>
      return snapshot.docs
          .map((doc) => MasterMealName.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Handle errors (e.g., logging, throwing a more specific exception)
      print('Error fetching food items from Firebase: $e');
      // Return an empty list on failure to prevent the app from crashing
      return [];
    }
  }
}