import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

class MasterDietPlanService{

  final Ref _ref; // Store Ref to access dynamic providers
  MasterDietPlanService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference<MasterDietPlanModel> get _collection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_mealTemplates)).
  withConverter<MasterDietPlanModel>(
    // Use the factory constructor to convert DocumentSnapshot to Model
    fromFirestore: (snapshot, _) => MasterDietPlanModel.fromFirestore(snapshot),
    // Use the instance method to convert Model to Map<String, dynamic>
    toFirestore: (plan, _) => plan.toFirestore(),
  );
  var logger = Logger(
    printer: PrettyPrinter(),
  );

  // Saves or updates a Master Diet Plan to Firestore.
  /// If plan.id is empty, it creates a new document (for New or Cloned plans).
  Future<void> savePlan(MasterDietPlanModel plan) async {
    final docRef = _collection.doc(plan.id.isEmpty ? null : plan.id);
    await docRef.set(plan);
  }

  Future<Map<String, String>> fetchMasterPlanNamesMap() async {
    try {
      final snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .orderBy('name', descending: false)
          .get();

      final Map<String, String> planMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? 'Unnamed Plan';
        if (name.isNotEmpty) {
          planMap[name] = doc.id;
        }
      }
      return planMap;
    } catch (e) {
      debugPrint('Error fetching master plan names: $e');
      return {};
    }
  }

    Future<MasterDietPlanModel> fetchPlanById(String id) async {
      logger.i('Fetching plan record for ID: $id');
      try {
        // 🎯 FIX 1: Use the typed collection. Doc is now a DocumentSnapshot<MasterDietPlanModel>.
        final doc = await _collection.doc(id).get();

        if (!doc.exists) {
          throw Exception('Client with ID $id not found.');
        }

        // 🎯 FIX 2: doc.data()! returns the already-converted MasterDietPlanModel.
        // Do NOT call MasterDietPlanModel.fromFirestore(doc) here.
        return doc.data()!;
      } catch (e, stack) {
        logger.e('Error fetching plan by ID: ${e.toString()}', error: e, stackTrace: stack);
        rethrow;
      }
    }



  Stream<List<MasterDietPlanModel>> streamAllPlans() {
    // 🎯 FIX 3: Use the typed collection.
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name',descending: false)
        .snapshots() // Stream<QuerySnapshot<MasterDietPlanModel>>
        .map((snapshot) => snapshot.docs
    // 🎯 FIX 4: Map using doc.data() which returns the already-converted Model.
        .map((doc) => doc.data())
        .toList());
  }
  Stream<List<MasterDietPlanModel>> streamAllPlansByCategoryIds({
    List<String>? categoryIds, // 🎯 NEW: Optional list of category IDs to filter by
  }) {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name',descending: false)
        .where('dietPlanCategoryIds', arrayContainsAny: categoryIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => doc.data())
        .toList());
  }
  /// Deletes a plan by ID.
  Future<void> deletePlan(String id) async {
    await _collection.doc(id).delete();
  }




}