import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';

class DiseaseMasterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'disease_master';

  // 1. Get all diseases (Active)
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

  // 2. Add a new disease
  Future<void> addDisease(DiseaseMasterModel disease) async {
    final newDoc = _firestore.collection(_collection).doc();
    final newDisease = disease.copyWith(id: newDoc.id);
    await newDoc.set(newDisease.toMap());
  }

  // 3. Update an existing disease
  Future<void> updateDisease(DiseaseMasterModel disease) async {
    if (disease.id.isEmpty) {
      throw Exception("Disease ID is required for update.");
    }
    await _firestore
        .collection(_collection)
        .doc(disease.id)
        .update(disease.toMap());
  }

  // 4. Soft Delete (Mark as deleted)
  Future<void> softDeleteDisease(String diseaseId) async {
    await _firestore
        .collection(_collection)
        .doc(diseaseId)
        .update({'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp()});
  }

  Future<List<DiseaseMasterModel>> getActiveDiseasesList() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .get();

    return snapshot.docs
        .map((doc) => DiseaseMasterModel.fromFirestore(doc))
        .toList();
  }

  // 🎯 UPDATED METHOD: Get a list of disease names as strings (Future)
  Future<List<String>> getDiseaseNameStrings() async {
    // Await the Future from the main method
    final diseases = await getActiveDiseasesList();
    return diseases.map((d) => d.enName).toList();
  }
}