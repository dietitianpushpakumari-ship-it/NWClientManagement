import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseMasterModel {
  final String id;
  // English name of the disease (e.g., "Type 2 Diabetes Mellitus")
  final String enName;
  // Localized names (e.g., {'hi': 'मधुमेह'})
  final Map<String, String> nameLocalized;
  // For soft-delete functionality
  final bool isDeleted;

  const DiseaseMasterModel({
    required this.id,
    required this.enName,
    this.nameLocalized = const {},
    this.isDeleted = false,
  });

  // --- Firestore Conversion ---

  factory DiseaseMasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final Map<String, dynamic> docData = data ?? {};

    // Safely cast the localization map
    Map<String, String> localizedNames = {};
    if (docData['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(docData['nameLocalized']);
    }

    return DiseaseMasterModel(
      id: doc.id,
      enName: docData['enName'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: docData['isDeleted'] ?? false,
    );
  }

  /// Convert DiseaseMasterModel object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': id.isEmpty ? FieldValue.serverTimestamp() : null,
    }..removeWhere((key, value) => value == null);
  }

  DiseaseMasterModel copyWith({
    String? id,
    String? enName,
    Map<String, String>? nameLocalized,
    bool? isDeleted,
  }) {
    return DiseaseMasterModel(
      id: id ?? this.id,
      enName: enName ?? this.enName,
      nameLocalized: nameLocalized ?? this.nameLocalized,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}