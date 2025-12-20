import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';

class InvestigationMasterService {

  final Ref _ref; // Store Ref to access dynamic providers
  InvestigationMasterService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_Investigation));

  /// Fetches a stream of all non-deleted diagnoses.
  Stream<List<InvestigationMasterModel>> getInvestigation() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InvestigationMasterModel.fromFirestore(doc))
        .toList());
  }

  /// Adds a new investigation or updates an existing one.
  Future<void> addOrUpdateInvestigation(InvestigationMasterModel investigation) async {
    final docRef = _collection.doc(investigation.id.isEmpty ? null : investigation.id);
    await docRef.set(
      investigation.toMap(),
      SetOptions(merge: true), // Use merge to only update fields present
    );
  }

  /// Soft deletes a investigation (sets isDeleted to true).
  Future<void> softDeleteInvestigation(String investigationId) async {
    await _collection.doc(investigationId).update({
      'isDeleted': true,
    });
  }


  Stream<List<InvestigationMasterModel>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InvestigationMasterModel.fromFirestore(doc))
        .toList());
  }
  Future<List<InvestigationMasterModel>> fetchAllInvestigationMaster() async {
    try {
      QuerySnapshot<Object?> snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .get(); // 🎯 Key change: .get() instead of .snapshots()

      // 2. Map the QuerySnapshot documents to a List<FoodItem>
      return snapshot.docs
          .map((doc) => InvestigationMasterModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Handle errors (e.g., logging, throwing a more specific exception)
      print('Error fetching diagnoses from Firebase: $e');
      // Return an empty list on failure to prevent the app from crashing
      return [];
    }
  }


  Future<List<InvestigationMasterModel>> fetchAllInvestigationMasterByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore 'whereIn' limitation: max 10 IDs. You may need to batch this.
    // For simplicity, assuming less than 10 for now.
    final snapshot = await _collection
        .where(FieldPath.documentId, whereIn: ids.take(10).toList())
        .get();

    return snapshot.docs.map((doc) => InvestigationMasterModel.fromFirestore(doc)).toList();
  }



  // Soft Delete operation (Swipe to Delete)
  Future<void> deleteInvestigation(String id) async {
      await _collection.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
}

