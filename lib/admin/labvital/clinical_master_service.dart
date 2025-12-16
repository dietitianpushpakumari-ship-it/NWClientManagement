import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';

class ClinicalMasterService {
  final Ref _ref; // Store Ref to access dynamic providers
  ClinicalMasterService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  // Collection Names (These are unused now that we use dynamic collectionName in methods)
  static const String colComplaints = 'master_complaints';
  static const String colAllergies = 'master_allergies';
  static const String colMedicines = 'master_medicines';
  static const String colClinicalNotes = 'master_clinical_notes';
  static const String colInstructions = 'master_instructions';

  CollectionReference _getCollection(String name) => _firestore.collection(name);

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

    final dataToSave = item.toMap();

    // Check if new item
    if (item.id.isEmpty) {
      dataToSave['createdAt'] = FieldValue.serverTimestamp();

      // Duplicate Check
      final duplicateCheck = await _getCollection(collectionName)
          .where('name', isEqualTo: trimmedName)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception("Item '$trimmedName' already exists.");
      }

      await _getCollection(collectionName).add(dataToSave);
    } else {
      // Update existing
      dataToSave['updatedAt'] = FieldValue.serverTimestamp();
      await _getCollection(collectionName).doc(item.id).update(dataToSave);
    }
  }

  // 🎯 4. GET ITEM BY ID (NEWLY ADDED)
  Future<ClinicalItemModel> getItemById(String collectionName, String id) async {
    final docSnapshot = await _getCollection(collectionName).doc(id).get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      throw Exception("Item with ID $id not found in $collectionName.");
    }
    return ClinicalItemModel.fromFirestore(docSnapshot);
  }

  // 5. ADD ITEM (Restored & Updated)
  // This creates a basic item (English only) for quick-add scenarios.
  Future<void> addItem(String collectionName, String name, Map<String,String> nameLocalized) async {
    // Note: Assuming nameLocalized is non-nullable based on the signature.
    await saveItem(collectionName, ClinicalItemModel(
      id: '',
      name: name,
      nameLocalized: nameLocalized,
    ));
  }

  // 6. Soft Delete
  Future<void> deleteItem(String collectionName, String id) async {
    await _getCollection(collectionName).doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}