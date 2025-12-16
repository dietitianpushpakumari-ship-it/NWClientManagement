import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: Assuming these providers/models are available
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

class LabTestConfigService {
  final FirebaseFirestore _firestore;
  final String collectionPath = MasterCollectionMapper.getPath(MasterEntity.entity_labTestConfig); // Dedicated collection for lab test definitions

  LabTestConfigService(this._firestore);

  // --- CRUD Operations ---

  // Fetches all lab test configurations
  Stream<List<LabTestConfigModel>> streamAllLabTests() {
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LabTestConfigModel.fromFirestore(doc)).toList();
    });
  }

  // Adds a new test configuration
  Future<void> addLabTest(LabTestConfigModel test) async {
    // Uses the ID from the model as the document ID (e.g., 'hemoglobin')
    await _firestore.collection(collectionPath).doc(test.id).set(test.toFirestore());
  }

  // Updates an existing test configuration
  Future<void> updateLabTest(LabTestConfigModel test) async {
    await _firestore.collection(collectionPath).doc(test.id).update(test.toFirestore());
  }

  // Deletes a test configuration
  Future<void> deleteLabTest(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  // --- Utility for Initial Upload (Migration from Dart file) ---
  Future<void> bulkUploadTests(Map<String, LabTestConfigModel> testsMap) async {
    final batch = _firestore.batch();
    for (var entry in testsMap.entries) {
      final docRef = _firestore.collection(collectionPath).doc(entry.key);
      batch.set(docRef, entry.value.toFirestore());
    }
    await batch.commit();
  }
}

final labTestConfigServiceProvider = Provider<LabTestConfigService>((ref) {
  // Assuming firebaseFirestoreProvider exists and provides an instance of FirebaseFirestore
  final firestore = ref.watch(firestoreProvider);
  return LabTestConfigService(firestore);
});

// Async value to hold all tests for use in UI/logic (optional, but useful)
final allLabTestsStreamProvider = StreamProvider.autoDispose<List<LabTestConfigModel>>((ref) {
  return ref.watch(labTestConfigServiceProvider).streamAllLabTests();
});