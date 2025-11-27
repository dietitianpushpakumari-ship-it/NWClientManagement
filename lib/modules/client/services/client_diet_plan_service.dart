import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart'
    show MasterDietPlanModel;

class ClientDietPlanService {
  static const String _clientCollection = 'clients';
  static const String _assignedPlansSubCollection = 'clientDietPlans';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  CollectionReference<ClientDietPlanModel> get _clientPlansCollection =>
      _firestore
          .collection('clientDietPlans')
          .withConverter<ClientDietPlanModel>(
        fromFirestore: (snapshot, _) =>
            ClientDietPlanModel.fromFirestore(snapshot),
        toFirestore: (plan, _) => plan.toFirestore(),
      );

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

  // --- Existing Methods ---

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
      isReadyToDeliver: true,
      isProvisional: true , // Default to provisional
    );

    await _clientPlansCollection.add(newClientPlan);
  }

  Future<void> updatePlan(ClientDietPlanModel plan) async {
    await _clientPlansCollection.doc(plan.id).set(plan, SetOptions(merge: true));
  }

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
      QuerySnapshot<Object?> snapshot = await _firestore
          .collection('clientDietPlans')
          .where('clientId', isEqualTo: clientId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => ClientDietPlanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> unassignPlanFromClient({
    required String clientId,
    required String masterPlanId,
  }) async {
    final querySnapshot = await _firestore
        .collection(_assignedPlansSubCollection)
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
}