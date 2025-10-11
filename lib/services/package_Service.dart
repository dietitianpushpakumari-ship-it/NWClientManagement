import '../models/package_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/client_model.dart';
import '../models/package_assignment_model.dart';
import '../models/payment_model.dart';

// Ensure your logger is correctly initialized elsewhere or use a simple print statement
final Logger _logger = Logger(/* ... */);


class PackageService {

  final CollectionReference _packageCollection = FirebaseFirestore.instance.collection('packages');

  Future<void> addPackage(PackageModel package) async {
    _logger.i('Adding new package: ${package.name}');
    try {
      await _packageCollection.add(package.toMap());
    } catch (e, stack) {
      _logger.e(
          'Error adding package: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to add package.');
    }
  }


// --- PACKAGE CRUD: READ (The method that was missing) ---

  Future<List<PackageModel>> getAllActivePackages() async {
    try {
      _logger.i('Fetching all active packages...');
      final snapshot = await _packageCollection
          .where('isActive', isEqualTo: true)
          .orderBy('price', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => PackageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error fetching packages: ${e.toString()}');
      throw Exception('Failed to load active packages.');
    }
  }


// --- PACKAGE CRUD: UPDATE ---

  Future<void> updatePackage(PackageModel package) async {
    if (package.id.isEmpty) {
      throw Exception('Package ID is required for update.');
    }
    _logger.i('Updating package: ${package.name} (${package.id})');
    try {
      await _packageCollection.doc(package.id).update(package.toMap());
    } catch (e, stack) {
      _logger.e('Error updating package: ${e.toString()}', error: e,
          stackTrace: stack);
      throw Exception('Failed to update package.');
    }
  }

// --- PACKAGE CRUD: DELETE (Logical delete by setting isActive=false) ---

  Future<void> deletePackage(String packageId) async {
    _logger.i('Attempting to deactivate package ID: $packageId');
    try {
      // We often prefer deactivating rather than permanently deleting
      await _packageCollection.doc(packageId).update({'isActive': false});
    } catch (e, stack) {
      _logger.e(
          'Error deleting/deactivating package: ${e.toString()}', error: e,
          stackTrace: stack);
      throw Exception('Failed to delete package.');
    }
  }


}
