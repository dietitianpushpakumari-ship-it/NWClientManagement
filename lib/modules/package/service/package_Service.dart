import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import '../model/package_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class PackageService {
  final Ref _ref;
  PackageService(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _packageCollection => _firestore.collection(MasterCollectionMapper.getPath(MasterEntity.entity_packages));

  // --- 1. CREATE ---
  Future<void> addPackage(PackageModel package) async {
    _logger.i('Adding new package: ${package.name}');
    try {
      await _packageCollection.add(package.toMap());
    } catch (e, stack) {
      _logger.e('Error adding package: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to add package.');
    }
  }

  // 🎯 NEW: Duplicate Logic
  Future<void> duplicatePackage(PackageModel original) async {
    _logger.i('Duplicating package: ${original.name}');
    try {
      final copyMap = original.toMap();

      // Setup the copy as a Fresh Draft
      copyMap['name'] = "${original.name} (Copy)";
      copyMap['isFinalized'] = false; // Unlock for editing
      copyMap['isActive'] = false;    // Hidden from Assignment screen
      copyMap.remove('updatedAt');    // New timestamp will be generated

      await _packageCollection.add(copyMap);
    } catch (e, stack) {
      _logger.e('Error duplicating package', error: e, stackTrace: stack);
      throw Exception('Failed to duplicate package.');
    }
  }

  // --- 2. READ ---

  // 🎯 FIXED: Removed .where('isActive', isEqualTo: true)
  // This ensures Drafts (isActive=false) are visible in the Admin List.
  // Note: The Assignment Page filters this list manually, so clients still won't see drafts.
  Stream<List<PackageModel>> streamPackages() {
    return _packageCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => PackageModel.fromFirestore(doc)).toList());
  }

  // Keep this for specific lookups if needed
  Future<List<PackageModel>> getAllActivePackages() async {
    try {
      final snapshot = await _packageCollection
          .where('isActive', isEqualTo: true)
          .orderBy('price', descending: false)
          .get();
      return snapshot.docs.map((doc) => PackageModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load active packages.');
    }
  }

  // --- 3. UPDATE & FINALIZE ---

  Future<void> updatePackage(PackageModel package) async {
    if (package.id.isEmpty) throw Exception('Package ID is required.');

    // Safety Check: Prevent editing if finalized
    if (package.isFinalized) {
      throw Exception("Finalized packages cannot be edited. Please create a new version.");
    }

    try {
      await _packageCollection.doc(package.id).update(package.toMap());
    } catch (e, stack) {
      _logger.e('Error updating package', error: e, stackTrace: stack);
      throw Exception('Failed to update package.');
    }
  }

  // 🎯 NEW: Finalize (Lock) Logic
  Future<void> finalizePackage(String packageId) async {
    try {
      await _packageCollection.doc(packageId).update({
        'isFinalized': true,
        'isActive': true, // Automatically activate for sales
      });
    } catch (e) {
      throw Exception('Failed to finalize package.');
    }
  }

  // --- 4. DELETE ---

  // 🎯 UPDATED: Logic to distinguish Draft vs Finalized
  Future<void> deletePackage(PackageModel package) async {
    // 1. If Finalized -> Prevent Delete (or Archive if you prefer)
    if (package.isFinalized) {
      throw Exception("Cannot delete a finalized package. Archive it instead.");
    }

    // 2. If Draft -> Hard Delete (Remove from DB)
    _logger.i('Permanently deleting draft package: ${package.id}');
    try {
      await _packageCollection.doc(package.id).delete();
    } catch (e, stack) {
      _logger.e('Error deleting package', error: e, stackTrace: stack);
      throw Exception('Failed to delete package.');
    }
  }

  // Legacy method support (Optional: redirects to soft delete/archive)
  Future<void> deactivatePackage(String packageId) async {
    await _packageCollection.doc(packageId).update({'isActive': false});
  }
}