// lib/admin/services/master_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Assuming dependency on Firestore Provider
import '../database_provider.dart';

class MasterDataService {
  final Ref _ref;
  final FirebaseFirestore _firestore;

  MasterDataService(this._ref) : _firestore = _ref.read(firestoreProvider);

  // Existing Future method kept for compatibility
  Future<Map<String, String>> fetchMasterList(String collectionPath) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where('isDeleted', isEqualTo: false)
        .get();

    return Map.fromEntries(
      snapshot.docs.map(
            (doc) => MapEntry(doc['name'] as String, doc.id),
      ),
    );
  }

  // 🎯 REQUIRED STREAM METHOD: This provides a stable data source.
  Stream<Map<String, String>> fetchMasterStream(String collectionPath) {
    return _firestore
        .collection(collectionPath)
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots() // Listen for real-time changes
        .map((snapshot) {
      return Map.fromEntries(
        snapshot.docs.map(
              (doc) => MapEntry(doc['name'] as String, doc.id),
        ),
      );
    });
  }

  Future<void> bulkUploadItems(String collectionPath, Map<String, Map<String, dynamic>> items) async {
    final batch = _firestore.batch();
    for (var entry in items.entries) {
      final docRef = _firestore.collection(collectionPath).doc(entry.key);
      // Data format expected: {id: docId, name: categoryName, isDeleted: false, ...}
      batch.set(docRef, entry.value);
    }
    await batch.commit();
  }

}


// Assuming the Riverpod provider for the services exists
final masterDataServiceProvider = Provider((ref) => MasterDataService(ref));