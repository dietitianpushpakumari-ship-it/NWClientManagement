import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/generic_master_model.dart';

/// A universal service for managing any master data collection.
/// (Habits, Diseases, Supplements, Investigations, Clinical Notes, etc.)
class GenericMasterService {
  final Ref _ref;
  final String collectionPath;

  GenericMasterService(this._ref, {required this.collectionPath});

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _collection => _firestore.collection(collectionPath);

  // --- READ ---

  /// Stream active items sorted by name
  Stream<List<GenericMasterModel>> streamActiveItems() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GenericMasterModel.fromFirestore(doc))
        .toList());
  }

  /// Stream simple name list (for dropdowns)
  Stream<List<String>> streamItemNames() {
    return streamActiveItems().map((items) => items.map((e) => e.name).toList());
  }

  /// Get Active items as Future
  Future<List<GenericMasterModel>> fetchActiveItems() async {
    final snapshot = await _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => GenericMasterModel.fromFirestore(doc)).toList();
  }

  // --- WRITE ---

  /// Save (Create or Update) with Duplicate Check
  Future<void> save(GenericMasterModel item) async {
    final data = item.toMap();

    if (item.id.isEmpty) {
      // CREATE
      // 1. Check Duplicates
      final duplicateCheck = await _collection
          .where('name', isEqualTo: item.name.trim())
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception("Item '${item.name}' already exists in this list.");
      }

      // 2. Add
      await _collection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // UPDATE
      await _collection.doc(item.id).update(data);
    }
  }

  /// Quick Add (Simple Name Only)
  Future<void> quickAdd(String name) async {
    final item = GenericMasterModel(id: '', name: name);
    await save(item);
  }

  // --- DELETE ---

  Future<void> delete(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _collection.doc(id).update({'isActive': isActive});
  }
}