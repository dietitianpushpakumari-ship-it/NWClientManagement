// lib/models/diet_plan_category.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a category for Diet Plans (e.g., "Weight Loss", "PCOS Management").
class DietPlanCategory {
  final String id;
  final String enName; // English name, serving as the primary identifier.
  final Map<String, String> nameLocalized; // A map of language codes to translated names.
  final bool isDeleted; // A flag for soft deleting.
  final DateTime? createdDate;

  const DietPlanCategory({
    required this.id,
    required this.enName,
    this.nameLocalized = const {},
    this.isDeleted = false,
    this.createdDate,
  });

  /// Factory constructor for creating from a Firestore document snapshot.
  factory DietPlanCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic> ?? {};

    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    return DietPlanCategory(
      id: doc.id,
      enName: data['enName'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: data['isDeleted'] ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert DietPlanCategory object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}