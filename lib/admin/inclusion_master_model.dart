import 'package:cloud_firestore/cloud_firestore.dart';

class InclusionMasterModel {
  final String id;
  final String name;
  final bool isActive;

  InclusionMasterModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory InclusionMasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InclusionMasterModel(
      id: doc.id,
      name: data['name'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}