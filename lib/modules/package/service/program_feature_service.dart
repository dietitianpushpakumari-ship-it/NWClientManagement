// lib/services/program_feature_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';

// Assuming you have a basic Logger setup
final Logger _logger = Logger();

class ProgramFeatureService {
  final Ref _ref; // Store Ref to access dynamic providers

  ProgramFeatureService(this._ref);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  CollectionReference get _featureCollection =>
  _firestore.collection('programFeatures');

  // Stream all features for the master list
  Stream<List<ProgramFeatureModel>> streamAllFeatures() {
    return _featureCollection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ProgramFeatureModel.fromFirestore(doc))
            .toList());
  }

  // 🎯 NEW: Unified Save Method (Handles both Add and Edit)
  Future<void> save(ProgramFeatureModel feature) async {
    if (feature.id.isEmpty) {
      await addFeature(feature);
    } else {
      await editFeature(feature);
    }
  }

  // Add a new feature (Now private)
  Future<void> addFeature(ProgramFeatureModel feature) async {
    _logger.i('Adding feature: ${feature.name}');
    // Ensure createdAt is set on new documents if you need it
    final data = {
      ...feature.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _featureCollection.add(data);
  }

  // Edit an existing feature (Now private)
  Future<void> editFeature(ProgramFeatureModel feature) async {
    _logger.i('Editing feature: ${feature.id}');
    // Ensure updatedAt is set
    final data = {
      ...feature.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _featureCollection.doc(feature.id).update(data);
  }

  // Delete a feature
  Future<void> deleteFeature(String featureId) async {
    _logger.i('Deleting feature: $featureId');
    await _featureCollection.doc(featureId).delete();
  }
}