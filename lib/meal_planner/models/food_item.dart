// lib/models/food_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single food item in the master food database.
class FoodItem {
  final String id;
  final String enName;
  final Map<String, String> nameLocalized;
  final String categoryId; // References FoodCategory.id
  final String servingUnitId; // References ServingUnit.id
  final bool isDeleted;

  // Nutritional Information (per standardServingSizeG)
  final double standardServingSizeG; // e.g., 100.0 (grams)
  final double caloriesPerStandardServing;
  final double proteinG;
  final double carbsG;
  final double fatG;

  final DateTime? createdDate;

  const FoodItem({
    required this.id,
    required this.enName,
    required this.categoryId,
    required this.servingUnitId,
    this.nameLocalized = const {},
    this.isDeleted = false,
    this.standardServingSizeG = 100.0,
    this.caloriesPerStandardServing = 0.0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
    this.createdDate,
  });

  /// Factory constructor for creating from a Firestore document snapshot.
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    return FoodItem(
      id: doc.id,
      enName: data['enName'] ?? '',
      categoryId: data['categoryId'] ?? '',
      servingUnitId: data['servingUnitId'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: data['isDeleted'] ?? false,
      standardServingSizeG: (data['standardServingSizeG'] as num?)?.toDouble() ?? 100.0,
      caloriesPerStandardServing: (data['caloriesPerStandardServing'] as num?)?.toDouble() ?? 0.0,
      proteinG: (data['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (data['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (data['fatG'] as num?)?.toDouble() ?? 0.0,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert FoodItem object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'nameLocalized': nameLocalized,
      'categoryId': categoryId,
      'servingUnitId': servingUnitId,
      'isDeleted': isDeleted,
      'standardServingSizeG': standardServingSizeG,
      'caloriesPerStandardServing': caloriesPerStandardServing,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}