// lib/models/program_feature_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramFeatureModel {
  final String id;
  final String name;
  final String description;
  final String featureType; // e.g., 'Dietary', 'Workout', 'Support'
  final bool isActive;
  final Map<String, String> nameLocalized;

  ProgramFeatureModel({
    required this.id,
    required this.name,
    this.description = '',
    this.featureType = 'Dietary',
    this.isActive = true,
    this.nameLocalized = const {},
  });

  factory ProgramFeatureModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    return ProgramFeatureModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      featureType: data['featureType'] ?? 'Dietary',
      isActive: data['isActive'] ?? true,
      nameLocalized: localizedNames,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'featureType': featureType,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'nameLocalized': nameLocalized,
    };
  }
}