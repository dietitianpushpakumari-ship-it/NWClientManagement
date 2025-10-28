// import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore if using Firebase

import 'package:nutricare_client_management/models/medical_history_master_model.dart';

class MedicalHistoryMasterService {
  // final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final String _collectionName = 'medicalHistoryMaster';

  // 1. Add/Edit
  Future<void> saveMedicalHistory(MedicalHistoryMasterModel history) async {
    // Implement Firestore/Database logic here
    // Example:
    /*
    if (history.id.isEmpty) {
      await _db.collection(_collectionName).add(history.toMap());
    } else {
      await _db.collection(_collectionName).doc(history.id).set(history.toMap());
    }
    */
    print('Medical History saved: ${history.name}');
  }

  // 2. Fetch All
  Future<List<MedicalHistoryMasterModel>> fetchAllMedicalHistory() async {
    // Implement Firestore/Database logic here
    // Example:
    /*
    final snapshot = await _db.collection(_collectionName).get();
    return snapshot.docs
        .map((doc) => MedicalHistoryMasterModel.fromMap(doc.id, doc.data()))
        .toList();
    */
    // MOCK DATA for initial setup
    return [
      MedicalHistoryMasterModel(id: 'dbt', name: 'Diabetes Mellitus', createdAt: DateTime.now()),
      MedicalHistoryMasterModel(id: 'htn', name: 'Hypertension', createdAt: DateTime.now()),
      MedicalHistoryMasterModel(id: 'thy', name: 'Thyroid Disorder', createdAt: DateTime.now()),
      MedicalHistoryMasterModel(id: 'pcos', name: 'PCOS', createdAt: DateTime.now()),
    ];
  }

  // 3. Delete
  Future<void> deleteMedicalHistory(String id) async {
    // Implement Firestore/Database logic here
    // Example:
    // await _db.collection(_collectionName).doc(id).delete();
    print('Medical History deleted: $id');
  }
}