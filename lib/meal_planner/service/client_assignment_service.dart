import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/master_diet_planner/client_diet_plan_model.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_item_model.dart';

class ClientDietPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  // 🎯 COLLECTION WITH CONVERTER
  CollectionReference<ClientDietPlanModel> get _clientPlansCollection =>
      _firestore.collection('clientDietPlans')
          .withConverter<ClientDietPlanModel>(
        fromFirestore: (snapshot, _) => ClientDietPlanModel.fromFirestore(snapshot),
        toFirestore: (plan, _) => plan.toFirestore(),
      );

  // 🎯 COMPLETE ASSIGNMENT FUNCTION
  /// Assigns a master plan template by cloning it and saving the copy as a new client plan.
  Future<void> assignPlanFromMaster({
    required String clientId,
    required MasterDietPlanModel masterPlan,
    required dynamic guidelineIds,
  }) async {
    // 1. Mark any currently active plan as inactive/archived
    // NOTE: This logic is crucial to prevent multiple active plans
    final activeSnapshot = await _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    for (var doc in activeSnapshot.docs) {
      await doc.reference.update({
        'isActive': false,
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Create the new client plan model from the master template
    // This utilizes the MasterDietPlanModel.clone() which creates the deep copy.
    final newClientPlan = ClientDietPlanModel.fromMaster(
      masterPlan,
      clientId,guidelineIds
    );

    try {
      // 3. Save the cloned plan. Firestore will use newClientPlan.toFirestore()
      await _clientPlansCollection.add(newClientPlan);
      logger.i('Successfully assigned master plan ${masterPlan.id} to client $clientId');
    } catch (e, stack) {
      logger.e('Error assigning plan: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // 🎯 FETCH ALL ASSIGNED PLANS (for the history list)
  Stream<List<ClientDietPlanModel>> streamAllNonDeletedPlansForClient(String clientId) {
    return _clientPlansCollection
        .where('clientId', isEqualTo: clientId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList()
    );
  }

  // 🎯 SOFT DELETE METHOD (Needed for swipe-to-delete)
  Future<void> softDeletePlan(String planId) async {
    await _clientPlansCollection.doc(planId).update({
      'isActive': false,
      'isArchived': true,
      'isDeleted': true, // The soft delete flag
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}