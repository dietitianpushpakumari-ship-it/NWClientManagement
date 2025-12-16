import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalItemModel {
  final String id;
  final String name; // English Name
  final Map<String, String> nameLocalized; // 🎯 Stores translations (e.g., {'hi': '...', 'od': '...'})
  final bool isDeleted;

  const ClinicalItemModel({
    required this.id,
    required this.name,
    this.nameLocalized = const {}, // Default empty
    this.isDeleted = false
  });

  factory ClinicalItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely parse the map
    Map<String, String> loc = {};
    if (data['nameLocalized'] != null) {
      loc = Map<String, String>.from(data['nameLocalized']);
    }

    return ClinicalItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameLocalized: loc,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLocalized': nameLocalized, // 🎯 Save to DB
      'isDeleted': isDeleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ClinicalItemModel copyWith({
    String? id,
    String? name,
    Map<String, String>? nameLocalized,
    bool? isDeleted,
  }) {
    return ClinicalItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLocalized: nameLocalized ?? this.nameLocalized,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

// ... (PrescribedMedication class remains unchanged)
class PrescribedMedication {
  final String medicineName;
  final String frequency;
  final String timing;

  const PrescribedMedication({
    required this.medicineName,
    required this.frequency,
    required this.timing,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'frequency': frequency,
      'timing': timing,
    };
  }

  factory PrescribedMedication.fromMap(Map<String, dynamic> map) {
    return PrescribedMedication(
      medicineName: map['medicineName'] ?? '',
      frequency: map['frequency'] ?? '1-0-0',
      timing: map['timing'] ?? 'After Food',
    );
  }



  @override
  String toString() => '$medicineName ($frequency, $timing)';
}