import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. Master Models (For the Database) ---

class ClinicalItemModel {
  final String id;
  final String name;
  final bool isDeleted;

  const ClinicalItemModel({required this.id, required this.name, this.isDeleted = false});

  factory ClinicalItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClinicalItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isDeleted': isDeleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// --- 2. Client Assignment Model (For the Vitals Form) ---

class PrescribedMedication {
  final String medicineName;
  final String frequency; // e.g., "1-0-1", "Once a day"
  final String timing;    // e.g., "Before Food", "After Food"

  const PrescribedMedication({
    required this.medicineName,
    required this.frequency,
    required this.timing,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'frequency': frequency,
      'timing': timing,
    };
  }

  // Create from Map
  factory PrescribedMedication.fromMap(Map<String, dynamic> map) {
    return PrescribedMedication(
      medicineName: map['medicineName'] ?? '',
      frequency: map['frequency'] ?? '1-0-0',
      timing: map['timing'] ?? 'After Food',
    );
  }

  // Helper for display
  @override
  String toString() => '$medicineName ($frequency, $timing)';
}