
import 'package:cloud_firestore/cloud_firestore.dart';

class InvestigationMasterModel {
  final String id;
  final String enName; // English name (e.g., "Gram")/ The physical type: 'mass' or 'volume'
  final Map<String, String> nameLocalized; // e.g., {'hi': 'ग्राम', 'od': 'ଗ୍ରାମ'}
  final bool isDeleted; // For soft-delete functionality

  const InvestigationMasterModel({
    required this.id,
    required this.enName,
    this.nameLocalized = const {},
    this.isDeleted = false,
  });

  // --- Firestore Conversion ---

  /// Factory constructor for creating a ServingUnit from a Firestore document snapshot.
  factory InvestigationMasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Default to empty map if data is null
    final Map<String, dynamic> docData = data ?? {};

    // Safely cast the localization map
    Map<String, String> localizedNames = {};
    if (docData['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(docData['nameLocalized']);
    }

    return InvestigationMasterModel(
      id: doc.id,
      enName: docData['enName'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: docData['isDeleted'] ?? false,
    );
  }

  /// Convert ServingUnit object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      // Add a timestamp for audit/ordering
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // --- Copy Method for easy updates ---

  /// Creates a copy of the ServingUnit with updated fields.
  InvestigationMasterModel copyWith({
    String? id,
    String? enName,
    Map<String, String>? nameLocalized,
    bool? isDeleted,
  }) {
    return InvestigationMasterModel(
      id: id ?? this.id,
      enName: enName ?? this.enName,
      nameLocalized: nameLocalized ?? this.nameLocalized,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}