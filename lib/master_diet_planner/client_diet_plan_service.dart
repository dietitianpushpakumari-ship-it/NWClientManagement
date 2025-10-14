// lib/services/client_diet_plan_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/master_diet_planner/client_diet_plan_model.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_item_model.dart' show MasterDietPlanModel;
// 🎯 NOTE: Adjust imports based on your project structure

class ClientDietPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // A simple logger for debugging (optional)
  final Logger logger = Logger();

  // 🎯 CRITICAL: Define the collection reference with the converter.
  // This tells Firestore to automatically run ClientDietPlanModel.fromFirestore(snapshot)
  // and ClientDietPlanModel.toFirestore(plan) on reads and writes, respectively.
  CollectionReference<ClientDietPlanModel> get _clientPlansCollection =>
      _firestore.collection('clientDietPlans')
          .withConverter<ClientDietPlanModel>(
        fromFirestore: (snapshot, _) => ClientDietPlanModel.fromFirestore(snapshot),
        toFirestore: (plan, _) => plan.toFirestore(),
      );

  // 🎯 CORE ASSIGNMENT FUNCTION
  /// Assigns a new plan, ensuring any existing active plan is archived.
  Future<void> assignPlanToClient({
    required String clientId,
    required MasterDietPlanModel masterPlan,
     List<String>? guidelineIds,
  }) async {
    // 1. Mark any currently active plan for this client as archived/inactive
    final activeSnapshot = await _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    for (var doc in activeSnapshot.docs) {
      // Use the helper method to safely archive the old plan
      await archivePlan(doc.id);
    }

    // 2. Create the new client plan model from the master template
    final newClientPlan = ClientDietPlanModel.fromMaster(
     masterPlan,
      clientId,guidelineIds ?? []
    );

    try {
      // 3. Save the copy. When using .add() on a typed collection, it automatically
      // calls the toFirestore converter defined above.
      await _clientPlansCollection.add(newClientPlan);
      logger.i('Successfully assigned plan ${masterPlan.name} to client $clientId');
    } catch (e, stack) {
      logger.e('Error assigning plan: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // 🎯 MANAGEMENT ACTIONS:

  /// Updates the content (meals/items) of an existing assigned plan.
  Future<void> updatePlan(ClientDietPlanModel plan) async {
    // Because the collection is typed, we can pass the model directly.
    await _clientPlansCollection.doc(plan.id).set(plan, SetOptions(merge: true));
  }

  /// Archives a plan (sets isActive=false, isArchived=true).
  Future<void> archivePlan(String planId) async {
    await _clientPlansCollection.doc(planId).update({
      'isActive': false,
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reactivates a historical/archived plan.
  Future<void> reactivatePlan(String planId) async {
    // NOTE: In a real app, you should archive the currently active plan first.
    await _clientPlansCollection.doc(planId).update({
      'isActive': true,
      'isArchived': false,
      'isDeleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🎯 SOFT DELETE: Archives and flags as deleted.
  Future<void> deletePlan(String planId) async {
    await _clientPlansCollection.doc(planId).update({
      'isActive': false,
      'isArchived': true, // Keep it archived for history/recovery
      'isDeleted': true, // Flag for hiding from main lists
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- FETCHING FOR CLIENT DASHBOARD ---

  /// Returns a stream of all non-deleted plans for a client, sorted by date.
  Stream<List<ClientDietPlanModel>> streamAllNonDeletedPlansForClient(String clientId) {
    return _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
    // 🎯 FIX: Use doc.data() to get the already-converted ClientDietPlanModel object.
    // This resolves the "Map<String, dynamic> cannot be assigned to ClientDietPlanModel" error.
    snapshot.docs.map((doc) => doc.data()).toList()
    );
  }

  /// Fetches a single plan by ID.
  Future<ClientDietPlanModel> fetchPlanById(String planId) async {
    final doc = await _clientPlansCollection.doc(planId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Client Diet Plan not found with ID: $planId');
    }
    // doc.data() is the converted object
    return doc.data()!;
  }

  Future<void> savePlan(ClientDietPlanModel plan) async {
    final docRef = _clientPlansCollection.doc(plan.id.isEmpty ? null : plan.id);
    await docRef.set(plan);
  }
}