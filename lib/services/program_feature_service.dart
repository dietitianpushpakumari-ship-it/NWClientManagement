// lib/services/program_feature_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';

final Logger _logger = Logger(/* ... */); // Reuse your existing logger setup

class ProgramFeatureService {
  final CollectionReference _featureCollection =
  FirebaseFirestore.instance.collection('programFeatures');

  // Stream all features for the master list
  Stream<List<ProgramFeatureModel>> streamAllFeatures() {
    return _featureCollection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ProgramFeatureModel.fromFirestore(doc))
            .toList());
  }

  // Add a new feature
  Future<void> addFeature(ProgramFeatureModel feature) async {
    _logger.i('Adding feature: ${feature.name}');
    // Use an auto-generated ID for new documents
    await _featureCollection.add(feature.toMap());
  }

  // Edit an existing feature
  Future<void> editFeature(ProgramFeatureModel feature) async {
    _logger.i('Editing feature: ${feature.id}');
    await _featureCollection.doc(feature.id).update(feature.toMap());
  }

  // Delete a feature
  Future<void> deleteFeature(String featureId) async {
    _logger.i('Deleting feature: $featureId');
    await _featureCollection.doc(featureId).delete();
  }
}