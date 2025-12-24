// lib/models/food_category.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a simple food category (e.g., "Grain", "Protein", "Vegetable").
class FoodCategory {
  final String id;
  final String name; // English name (e.g., "Grain")
  final Map<String, String> nameLocalized; // e.g., {'hi': 'अनाज'}
  final bool isDeleted;
  final int displayOrder;
  final DateTime? createdDate;

  const FoodCategory({
    required this.id,
    required this.name,
    this.nameLocalized = const {},
    this.isDeleted = false,
    this.displayOrder = 0,
    this.createdDate,
  });

  /// Factory constructor for creating from a Firestore document snapshot.
  factory FoodCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    return FoodCategory(
      id: doc.id,
      name: data['name'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: data['isDeleted'] ?? false,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert FoodCategory object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      'displayOrder': displayOrder,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}