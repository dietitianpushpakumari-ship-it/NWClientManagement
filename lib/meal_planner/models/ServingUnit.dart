// lib/models/serving_unit.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a simple unit of measure for food items (e.g., "g", "ml", "cup").
/// This models supports multiple language translations for the unit name.
class ServingUnit {
  final String id;
  final String enName; // English name (e.g., "Gram")
  final String abbreviation; // Symbol (e.g., "g")
  final String baseUnit; // The physical type: 'mass' or 'volume'
  final Map<String, String> nameLocalized; // e.g., {'hi': 'ग्राम', 'od': 'ଗ୍ରାମ'}
  final bool isDeleted; // For soft-delete functionality

  const ServingUnit({
    required this.id,
    required this.enName,
    required this.abbreviation,
    required this.baseUnit,
    this.nameLocalized = const {},
    this.isDeleted = false,
  });

  // --- Firestore Conversion ---

  /// Factory constructor for creating a ServingUnit from a Firestore document snapshot.
  factory ServingUnit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Default to empty map if data is null
    final Map<String, dynamic> docData = data ?? {};

    // Safely cast the localization map
    Map<String, String> localizedNames = {};
    if (docData['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(docData['nameLocalized']);
    }

    return ServingUnit(
      id: doc.id,
      enName: docData['enName'] ?? '',
      abbreviation: docData['abbreviation'] ?? '',
      baseUnit: docData['baseUnit'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: docData['isDeleted'] ?? false,
    );
  }

  /// Convert ServingUnit object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'abbreviation': abbreviation,
      'baseUnit': baseUnit,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      // Add a timestamp for audit/ordering
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // --- Copy Method for easy updates ---

  /// Creates a copy of the ServingUnit with updated fields.
  ServingUnit copyWith({
    String? id,
    String? enName,
    String? abbreviation,
    String? baseUnit,
    Map<String, String>? nameLocalized,
    bool? isDeleted,
  }) {
    return ServingUnit(
      id: id ?? this.id,
      enName: enName ?? this.enName,
      abbreviation: abbreviation ?? this.abbreviation,
      baseUnit: baseUnit ?? this.baseUnit,
      nameLocalized: nameLocalized ?? this.nameLocalized,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}