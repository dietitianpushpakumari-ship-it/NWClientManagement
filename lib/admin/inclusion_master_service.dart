import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/inclusion_master_model.dart';

import 'database_provider.dart';

class InclusionMasterService {
  final Ref _ref; // Store Ref to access dynamic providers

  InclusionMasterService(this._ref);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection =>
  _firestore.collection('inclusion_master');

  // Stream Active Inclusions
  Stream<List<InclusionMasterModel>> streamAllInclusions() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => InclusionMasterModel.fromFirestore(doc))
        .toList());
  }

  // Create
  Future<void> addInclusion(String name) async {
    await _collection.add({
      'name': name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update
  Future<void> updateInclusion(String id, String name) async {
    await _collection.doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Soft Delete
  Future<void> deleteInclusion(String id) async {
    await _collection.doc(id).update({'isActive': false});
  }

  // Fetch by IDs (Helper to resolve names for saving denormalized data)
  Future<List<String>> resolveNames(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Note: whereIn is limited to 10. For larger lists, fetch all or batch.
    // For simplicity, we'll assume <10 inclusions per package usually.
    try {
      final snap = await _collection.where(FieldPath.documentId, whereIn: ids.take(10).toList()).get();
      return snap.docs.map((d) => d['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}