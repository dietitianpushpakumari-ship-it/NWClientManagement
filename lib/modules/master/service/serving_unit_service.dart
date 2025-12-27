// lib/services/serving_unit_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

import '../../../master/model/ServingUnit.dart';


/// A services class to manage CRUD operations for the ServingUnit master data.
class ServingUnitService {

  final Ref _ref; // Store Ref to access dynamic providers
  ServingUnitService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _unitsCollection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_ServingUnits));

  // --- READ Operations ---

  /// Provides a stream of all *active* serving units, ordered by name.
  /// This is suitable for real-time list screens.
  Stream<List<ServingUnit>> streamAllActiveUnits() {
    return _unitsCollection
    // Only fetch units that have not been soft-deleted
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ServingUnit.fromFirestore(doc))
        .toList());
  }

  // --- CREATE & UPDATE Operations ---

  /// Adds a new ServingUnit or updates an existing one.
  Future<void> saveUnit(ServingUnit unit) async {
    final Map<String, dynamic> data = unit.toMap();

    if (unit.id.isEmpty) {
      // CREATE: ID is empty, so add a new document
      // We use a predefined abbreviation as the ID, or a random ID if abbreviation is missing
      final String docId = unit.abbreviation.isNotEmpty
          ? unit.abbreviation.toLowerCase()
          : _unitsCollection.doc().id;

      // Use set instead of add to control the document ID
      await _unitsCollection.doc(docId).set(data);
    } else {
      // UPDATE: ID exists, so merge new data into the existing document
      // Exclude 'id' from the map, as it's the document key
      data.remove('id');
      await _unitsCollection.doc(unit.id).update(data);
    }
  }

  // --- DELETE Operations (Soft Delete) ---

  /// Performs a soft-delete by setting the 'isDeleted' flag to true.
  Future<void> softDeleteUnit(String unitId) async {
    try {
      await _unitsCollection.doc(unitId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error soft-deleting Serving Unit $unitId: $e');
      throw Exception('Failed to soft-delete serving unit.');
    }
  }

  /// Permanently deletes the document from Firestore.
  /// USE WITH CAUTION. Typically only used for cleaning up truly unwanted data.
  Future<void> hardDeleteUnit(String unitId) async {
    try {
      await _unitsCollection.doc(unitId).delete();
    } catch (e) {
      print('Error hard-deleting Serving Unit $unitId: $e');
      throw Exception('Failed to permanently delete serving unit.');
    }
  }
}