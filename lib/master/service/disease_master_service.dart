import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/disease_master_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

class DiseaseMasterService {
  final Ref _ref; // Store Ref to access dynamic providers
  DiseaseMasterService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  final String _collection = MasterCollectionPath.collection_master_disease;

  // 1. Check for Duplicates
  Future<bool> checkDuplicate(String enName) async {
    final snapshot = await _firestore.collection(_collection)
        .where('enName', isEqualTo: enName)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // 2. Get All (Future)
  Future<List<DiseaseMasterModel>> getActiveDiseasesList() async {
    final snapshot = await _firestore.collection(_collection)
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .get();
    return snapshot.docs.map((doc) => DiseaseMasterModel.fromFirestore(doc)).toList();
  }

  // 3. Add
  Future<void> addDisease(DiseaseMasterModel disease) async {
    if (await checkDuplicate(disease.enName)) {
      throw Exception("Disease '${disease.enName}' already exists.");
    }
    final newDoc = _firestore.collection(_collection).doc();
    final newDisease = disease.copyWith(id: newDoc.id);
    await newDoc.set(newDisease.toMap());
  }

  // ... (Keep existing update, delete, stream methods)
  Stream<List<DiseaseMasterModel>> getActiveDiseases() {
    return _firestore
        .collection(_collection)
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DiseaseMasterModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> updateDisease(DiseaseMasterModel disease) async {
    if (disease.id.isEmpty) {
      throw Exception("Disease ID is required for update.");
    }
    await _firestore
        .collection(_collection)
        .doc(disease.id)
        .update(disease.toMap());
  }

  Future<void> softDeleteDisease(String diseaseId) async {
    await _firestore
        .collection(_collection)
        .doc(diseaseId)
        .update({'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp()});
  }
}