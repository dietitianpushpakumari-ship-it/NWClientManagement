import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';

class SupplimentMasterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'suppliments';
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection("suppliments");

  /// Fetches a stream of all non-deleted diagnoses.
  Stream<List<SupplimentMasterModel>> getSupplimentMaster() {
    return _db
        .collection(_collectionName)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SupplimentMasterModel.fromFirestore(doc))
        .toList());
  }

  /// Adds a new investigation or updates an existing one.
  Future<void> addOrUpdateSupplimentMaster(SupplimentMasterModel suppliment) async {
    final docRef = _db.collection(_collectionName).doc(suppliment.id.isEmpty ? null : suppliment.id);
    await docRef.set(
      suppliment.toMap(),
      SetOptions(merge: true), // Use merge to only update fields present
    );
  }

  /// Soft deletes a suppliment (sets isDeleted to true).
  Future<void> softDeleteSupplimentMaster(String SupplimentMasterId) async {
    await _db.collection(_collectionName).doc(SupplimentMasterId).update({
      'isDeleted': true,
    });
  }


  Stream<List<SupplimentMasterModel>> streamAllActive() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('enTitle')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SupplimentMasterModel.fromFirestore(doc))
        .toList());
  }
  Future<List<SupplimentMasterModel>> fetchAllSupplimentMaster() async {
    try {
      QuerySnapshot<Object?> snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .get(); // 🎯 Key change: .get() instead of .snapshots()

      // 2. Map the QuerySnapshot documents to a List<FoodItem>
      return snapshot.docs
          .map((doc) => SupplimentMasterModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Handle errors (e.g., logging, throwing a more specific exception)
      print('Error fetching diagnoses from Firebase: $e');
      // Return an empty list on failure to prevent the app from crashing
      return [];
    }
  }


  Future<List<SupplimentMasterModel>> fetchAllSupplimentMasterMasterByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore 'whereIn' limitation: max 10 IDs. You may need to batch this.
    // For simplicity, assuming less than 10 for now.
    final snapshot = await _collection
        .where(FieldPath.documentId, whereIn: ids.take(10).toList())
        .get();

    return snapshot.docs.map((doc) => SupplimentMasterModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteSupplementation(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}

