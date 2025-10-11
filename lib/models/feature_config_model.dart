// lib/models/feature_config_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeatureScope { global, client }

class FeatureConfigModel {
  final String id;
  final String title;
  final String description;
  final bool isEnabled;
  final String section;
  final FeatureScope scope; // 🎯 NEW: Defines if this is a global switch or a switch for the client-side option

  FeatureConfigModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.section,
    required this.scope, // 🎯 Added to constructor
  });

  factory FeatureConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse FeatureScope safely
    final scopeString = data['scope'] as String? ?? 'global';
    final scope = scopeString.toLowerCase() == 'client' ? FeatureScope.client : FeatureScope.global;

    return FeatureConfigModel(
      id: doc.id,
      title: data['title'] ?? 'Untitled Feature',
      description: data['description'] ?? '',
      isEnabled: data['isEnabled'] ?? false,
      section: data['section'] ?? 'Uncategorized',
      scope: scope, // 🎯 Added to factory
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isEnabled': isEnabled,
      'section': section,
      'scope': scope.toString().split('.').last, // Convert enum back to string (e.g., 'global')
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}