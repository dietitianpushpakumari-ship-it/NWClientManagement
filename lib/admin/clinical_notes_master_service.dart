// lib/master/service/clinical_notes_master_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/simple_item_master_model.dart';

import 'package:nutricare_client_management/master/model/master_constants.dart';

class ClinicalNotesMasterService {
  final FirebaseFirestore _firestore;
  final String _collectionPath = MasterCollectionPath.collection_clinicalnote;

  ClinicalNotesMasterService(this._firestore);

  // Provides a stable stream using .snapshots()
  Stream<List<SimpleMasterItemModel>> getClinicalNotes() {
    return _firestore
        .collection(_collectionPath)
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SimpleMasterItemModel.fromFirestore(doc))
          .where((item) => item.isValid)
          .toList();
    });
  }
}

final clinicalNotesMasterServiceProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ClinicalNotesMasterService(firestore);
});