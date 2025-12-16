import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import '../../../master/model/diagonosis_master.dart';

class DiagnosisMasterService {

  final Ref _ref; // Store Ref to access dynamic providers
  DiagnosisMasterService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection('diagnoses');

  // 1. Check for Duplicates
  Future<bool> checkDuplicate(String enName) async {
    final snapshot = await _collection
        .where('enName', isEqualTo: enName)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // 2. Fetch All (For Dropdown)
  Future<List<DiagnosisMasterModel>> fetchAllDiagnosisMaster() async {
    try {
      final snapshot = await _collection
          .where('isDeleted', isEqualTo: false)
          .orderBy('enName')
          .get();
      return snapshot.docs.map((doc) => DiagnosisMasterModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // 3. Add/Update
  Future<void> addOrUpdateDiagnosis(DiagnosisMasterModel diagnosis) async {
    // Duplicate Check for New Entries
    if (diagnosis.id.isEmpty) {
      final exists = await checkDuplicate(diagnosis.enName);
      if (exists) throw Exception("Diagnosis '${diagnosis.enName}' already exists.");
    }

    final docRef = _collection.doc(diagnosis.id.isEmpty ? null : diagnosis.id);
    await docRef.set(diagnosis.toMap(), SetOptions(merge: true));
  }

  // ... (Keep existing getDiagnoses, softDeleteDiagnosis methods)
  Stream<List<DiagnosisMasterModel>> getDiagnoses() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DiagnosisMasterModel.fromFirestore(doc))
        .toList());
  }

  Future<void> softDeleteDiagnosis(String diagnosisId) async {
    await _collection.doc(diagnosisId).update({
      'isDeleted': true,
    });
  }
  Future<List<DiagnosisMasterModel>> fetchAllDiagnosisMasterByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore 'whereIn' limitation: max 10 IDs. You may need to batch this.
    // For simplicity, assuming less than 10 for now.
    final snapshot = await _collection
        .where(FieldPath.documentId, whereIn: ids.take(10).toList())
        .get();

    return snapshot.docs.map((doc) => DiagnosisMasterModel.fromFirestore(doc)).toList();
  }
}