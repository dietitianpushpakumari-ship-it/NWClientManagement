// lib/services/config_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/feature_config_model.dart';

final Logger _logger = Logger(/* ... */); // Reuse your existing logger setup

class ConfigService {
  final CollectionReference _featureCollection = FirebaseFirestore.instance.collection('config').doc('feature_toggles').collection('modules');


  /// Streams all feature configurations, grouped by section.
  Stream<Map<String, List<FeatureConfigModel>>> streamAllFeatures() {
    // 🎯 Group the list by the 'scope' for the Master Management Screen
    return _featureCollection.orderBy('scope').orderBy('title').snapshots().map((snapshot) {
      final Map<String, List<FeatureConfigModel>> groupedFeatures = {};

      for (var doc in snapshot.docs) {
        final feature = FeatureConfigModel.fromFirestore(doc);
        // Use the scope for primary grouping in the Master list
        final scopeKey = feature.scope.toString().split('.').last;

        if (!groupedFeatures.containsKey(scopeKey)) {
          groupedFeatures[scopeKey] = [];
        }
        groupedFeatures[scopeKey]!.add(feature);
      }
      return groupedFeatures;
    });
  }

  /// Updates the status (isEnabled) of a single feature.
  Future<void> updateFeatureStatus(String featureId, bool isEnabled) async {
    _logger.i('Updating feature $featureId status to $isEnabled');
    try {
      await _featureCollection.doc(featureId).update({
        'isEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('Feature $featureId status updated successfully.');
    } catch (e) {
      _logger.e('Error updating feature $featureId: ${e.toString()}');
      throw Exception('Failed to update feature status.');
    }
  }

  // 🎯 NEW: Adds a new feature configuration.
  Future<void> addFeature(FeatureConfigModel feature) async {
    _logger.i('Adding new feature: ${feature.title}');
    try {
      // Use the feature's ID (which should be unique, e.g., a slugified name) as the doc ID
      await _featureCollection.doc(feature.id).set(feature.toMap());
      _logger.i('Feature ${feature.id} added successfully.');
    } catch (e) {
      _logger.e('Error adding feature ${feature.id}: ${e.toString()}');
      throw Exception('Failed to add feature.');
    }
  }

  // 🎯 NEW: Edits an existing feature configuration.
  Future<void> editFeature(FeatureConfigModel feature) async {
    _logger.i('Editing feature: ${feature.id}');
    try {
      await _featureCollection.doc(feature.id).update(feature.toMap());
      _logger.i('Feature ${feature.id} updated successfully.');
    } catch (e) {
      _logger.e('Error editing feature ${feature.id}: ${e.toString()}');
      throw Exception('Failed to edit feature.');
    }
  }

  // 🎯 NEW: Deletes a feature configuration.
  Future<void> deleteFeature(String featureId) async {
    _logger.i('Deleting feature: $featureId');
    try {
      await _featureCollection.doc(featureId).delete();
      _logger.i('Feature $featureId deleted successfully.');
    } catch (e) {
      _logger.e('Error deleting feature $featureId: ${e.toString()}');
      throw Exception('Failed to delete feature.');
    }
  }
}