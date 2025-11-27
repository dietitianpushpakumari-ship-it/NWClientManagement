import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';


class ClinicalMasterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection Names
  static const String colComplaints = 'master_complaints';
  static const String colAllergies = 'master_allergies';
  static const String colMedicines = 'master_medicines';
  static const String colClinicalNotes = 'master_clinical_notes'; // 🎯 NEW
  static const String colInstructions = 'master_instructions';    // 🎯 NEW

  CollectionReference _getCollection(String name) => _db.collection(name);

  // 1. Stream Active Items
  Stream<List<ClinicalItemModel>> streamActiveItems(String collectionName) {
    return _getCollection(collectionName)
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ClinicalItemModel.fromFirestore(doc)).toList());
  }

  // 2. Stream Strings (For Dropdowns/Autocomplete)
  Stream<List<String>> streamItemNames(String collectionName) {
    return streamActiveItems(collectionName).map((list) => list.map((e) => e.name).toList());
  }

  // 3. CORE SAVE METHOD (Add/Update with Duplicate Check)
  Future<void> saveItem(String collectionName, ClinicalItemModel item) async {
    final trimmedName = item.name.trim();
    if (trimmedName.isEmpty) return;

    if (item.id.isEmpty) {
      // CHECK DUPLICATE BEFORE CREATE
      final duplicateCheck = await _getCollection(collectionName)
          .where('name', isEqualTo: trimmedName)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) return; // Prevent duplicate

      await _getCollection(collectionName).add({
        'name': trimmedName,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // UPDATE
      await _getCollection(collectionName).doc(item.id).update({
        'name': trimmedName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addItem(String collectionName, String name) async {
    await saveItem(collectionName, ClinicalItemModel(id: '', name: name));
  }

  // 3. Soft Delete
  Future<void> deleteItem(String collectionName, String id) async {
    await _getCollection(collectionName).doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}