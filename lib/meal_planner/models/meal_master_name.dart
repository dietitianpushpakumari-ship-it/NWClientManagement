// lib/models/master_meal_name.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a master meal name (e.g., "Breakfast").
class MasterMealName {
  final String id;
  final String enName;
  final Map<String, String> nameLocalized;
  final bool isDeleted;
  final DateTime? createdDate;

  const MasterMealName({
    this.id = '',
    this.enName = '',
    this.nameLocalized = const {},
    this.isDeleted = false,
    this.createdDate,
  });

  /// Factory constructor for creating from a Firestore document snapshot.
  factory MasterMealName.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    return MasterMealName(
      id: doc.id,
      enName: data['enName'] ?? '',
      nameLocalized: localizedNames,
      isDeleted: data['isDeleted'] ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert MasterMealName object to a Map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'enName': enName,
      'nameLocalized': nameLocalized,
      'isDeleted': isDeleted,
      // Only set createdDate on initial creation, otherwise use server timestamp for update
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, enName, nameLocalized, isDeleted, createdDate];
}