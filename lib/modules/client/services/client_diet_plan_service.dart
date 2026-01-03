import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';

class ClientDietPlanService {
  final Ref _ref; // Store Ref to access dynamic providers
  ClientDietPlanService(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference<ClientDietPlanModel> get _clientPlansCollection => _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientMealPlan))
      .withConverter<ClientDietPlanModel>(
    fromFirestore: (snapshot, _) =>
        ClientDietPlanModel.fromFirestore(snapshot),
    toFirestore: (plan, _) => plan.toFirestore(),
  );

  CollectionReference<MasterDietPlanModel> get _collection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_mealTemplates)).
  withConverter<MasterDietPlanModel>(
    // Use the factory constructor to convert DocumentSnapshot to Model
    fromFirestore: (snapshot, _) => MasterDietPlanModel.fromFirestore(snapshot),
    // Use the instance method to convert Model to Map<String, dynamic>
    toFirestore: (plan, _) => plan.toFirestore(),
  );

  CollectionReference get _assignedPlansSubCollection => _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientMealPlan));

  final Logger logger = Logger();

  // lib/modules/client/services/diet_plan_service.dart

  Future<void> duplicatePlan(ClientDietPlanModel oldPlan) async {
    try {
      // 1. Create a copy with reset IDs and metadata
      final newPlan = oldPlan.copyWith(
        id: '', // Resetting ID tells Firestore to create a new document
        name: "${oldPlan.name} (Copy)",
        isProvisional: true, // Mark as draft/provisional by default
      );
// 🎯 Use the correct collection reference instead of hardcoded 'diet_plans'
      final docRef = _clientPlansCollection.doc();
      await docRef.set(newPlan.copyWith(id: docRef.id));
      // 4. Save to the 'diet_plans' collection

    } catch (e) {
      throw Exception("Failed to duplicate diet plan: $e");
    }
  }

  // 🎯 CORE: Set as Primary (Exclusive Active Status)
  Future<void> setAsPrimary(String clientId, String planId) async {
    try {
      // 1. Find all currently active plans for this client
      final activeSnapshot = await _clientPlansCollection
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      // 2. Deactivate all other plans
      for (var doc in activeSnapshot.docs) {
        if (doc.id != planId) {
          batch.update(doc.reference, {
            'isActive': false,
            'isArchived': true, // Archive old primaries
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Activate the target plan
      final targetRef = _clientPlansCollection.doc(planId);
      batch.update(targetRef, {
        'isActive': true,
        'isArchived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      logger.i('Plan $planId set as Primary for client $clientId');
    } catch (e) {
      logger.e('Error setting primary plan: $e');
      rethrow;
    }
  }

  // 🎯 TOGGLE PROVISIONAL STATUS
  Future<void> toggleProvisional(String planId, bool currentStatus) async {
    try {
      await _clientPlansCollection.doc(planId).update({
        'isProvisional': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Toggled provisional status for plan $planId');
    } catch (e) {
      logger.e('Error toggling provisional status: $e');
      rethrow;
    }
  }

  // lib/modules/client/services/client_diet_plan_service.dart

  // lib/modules/client/services/client_diet_plan_service.dart

  Future<String> assignPlanToClientAndReturnId({
    required String clientId,
    required MasterDietPlanModel masterPlan,
    String? sessionId,
  }) async {
    try {
      final collection = _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientMealPlan));

      // 1. Overwrite Logic: Remove existing session drafts
      if (sessionId != null) {
        final existing = await collection
            .where('clientId', isEqualTo: clientId)
            .where('sessionId', isEqualTo: sessionId)
            .where('isProvisional', isEqualTo: true)
            .get();

        for (var doc in existing.docs) {
          await doc.reference.delete();
        }
      }

      // 2. Prepare the new Model
      final newClientPlan = ClientDietPlanModel.fromMaster(
        masterPlan,
        clientId,
        [],
      ).copyWith(
        sessionId: sessionId,
        isProvisional: true,
        assignedDate: Timestamp.now(),
      );

      // 3. 🎯 FIX: Convert model to Map for Firestore .add()
      // Ensure toMap() is defined in your ClientDietPlanModel
      final docRef = await collection.add(newClientPlan.toMap());

      // 4. Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception("Failed to assign plan: $e");
    }
  }

  Future<void> assignPlanToClient({
    required String clientId,
    required MasterDietPlanModel masterPlan,
    List<String>? guidelineIds,
  }) async {
    // Auto-archive existing active plans before assigning new one
    final activeSnapshot = await _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    for (var doc in activeSnapshot.docs) {
      await archivePlan(doc.id);
    }

    // Create new plan (Locked by default as per requirement)
    final newClientPlan = ClientDietPlanModel.fromMaster(
      masterPlan,
      clientId,
      guidelineIds ?? [],
    ).copyWith(
      isReadyToDeliver: true, // This method implies readiness for delivery
      isProvisional: true , // Default to provisional
    );

    await _clientPlansCollection.add(newClientPlan);
  }

  Future<void> updatePlan(ClientDietPlanModel plan) async {
    await _clientPlansCollection.doc(plan.id).set(plan, SetOptions(merge: true));
  }
  // ... (rest of the file is unchanged)

  Future<void> archivePlan(String planId) async {
    await _clientPlansCollection.doc(planId).update({
      'isActive': false,
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    await _clientPlansCollection.doc(planId).update({
      'isActive': false,
      'isArchived': true,
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ClientDietPlanModel>> streamAllNonDeletedPlansForClient(String clientId) {
    return _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  // lib/modules/client/services/client_diet_plan_service.dart

  Future<void> saveClientPlanAsMaster(ClientDietPlanModel clientPlan, String templateName) async {
    try {
      // 1. Convert Client Model back to Master Model structure
      final masterTemplate = MasterDietPlanModel(
        id: '', // Will be generated by Firestore
        name: templateName,
        description: "Saved from client: ${clientPlan.name}",
        days: clientPlan.days, // Reuse the existing meal/day structure
        isActive: true,
        createdAt: Timestamp.now(),
      );

      // 2. Save to the master_mealTemplates collection
      final docRef = await _firestore
          .collection(MasterCollectionMapper.getPath(MasterEntity.entity_mealTemplates))
          .add(masterTemplate.toFirestore());

      // 3. Update with ID
      await docRef.update({'id': docRef.id});

      logger.i('Client plan saved as master template: ${docRef.id}');
    } catch (e) {
      throw Exception("Failed to save as master template: $e");
    }
  }

  Future<ClientDietPlanModel> fetchPlanById(String planId) async {
    final doc = await _clientPlansCollection.doc(planId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Client Diet Plan not found with ID: $planId');
    }
    return doc.data()!;
  }

  Future<void> savePlan(ClientDietPlanModel plan) async {
    final docRef = _clientPlansCollection.doc(plan.id.isEmpty ? null : plan.id);
    await docRef.set(plan);
  }

  Future<List<ClientDietPlanModel>> fetchAllActivePlans(String clientId) async {
    try {
      final snapshot = await _clientPlansCollection
          .where('clientId', isEqualTo: clientId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('name')
          .get();

      // 🎯 FIX: Directly return data()
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.e("Error fetching active plans: $e");
      return [];
    }
  }

  Future<List<ClientDietPlanModel>> getPlansForHistory(String clientId) async {
    try {
      final snapshot = await _clientPlansCollection
          .where('clientId', isEqualTo: clientId)
          .where('isDeleted', isEqualTo: false) // Only exclude deleted
          .orderBy('assignedDate', descending: true)
          .get();

      // 🎯 FIX: doc.data() is ALREADY ClientDietPlanModel. Do not call fromFirestore again.
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.e("Error fetching history plans: $e");
      return [];
    }
  }

  Future<void> unassignPlanFromClient({
    required String clientId,
    required String masterPlanId,
  }) async {
    final querySnapshot = await _assignedPlansSubCollection
        .where('clientId', isEqualTo: clientId)
        .where('masterPlanId', isEqualTo: masterPlanId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docReference = querySnapshot.docs.first.reference;
      await docReference.delete();
    }
  }

  Stream<List<String>> streamAssignedPlanIds(String clientId) {
    return _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data().masterPlanId).toList();
    });
  }
  Future<void> hardDeletePlan(String planId) async {
    // If it's a session draft, you might prefer a hard delete to clear the UI
    await _clientPlansCollection.doc(planId).delete();
    logger.i('Plan $planId hard deleted from session.');
  }

  // lib/screens/assigned_diet_plan_list_screen.dart
// lib/services/client_management_service.dart

  Future<void> updatePlanProvisionalStatus({
    required String clientId,
    required String planId,
    required bool currentStatus,
  }) async {
    try {
      // 🎯 Uses the multi-tenant firestore instance
      await _clientPlansCollection
          .doc(planId)
          .update({
        'isProvisional': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Service Error: Failed to toggle provisional status: $e");
      rethrow;
    }
  }
}