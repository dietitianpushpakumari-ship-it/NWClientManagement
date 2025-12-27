import 'package:cloud_firestore/cloud_firestore.dart';

class RoleConfigModel {
  final String id;
  final String name; // e.g., "Senior Dietitian", "Front Desk"
  final List<String> allowedModuleIds; // IDs from AppModule
  final bool isSystem; // If true, cannot be deleted (e.g., 'clinicAdmin')

  RoleConfigModel({
    required this.id,
    required this.name,
    this.allowedModuleIds = const [],
    this.isSystem = false,
  });

  factory RoleConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoleConfigModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Role',
      allowedModuleIds: List<String>.from(data['allowedModuleIds'] ?? []),
      isSystem: data['isSystem'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allowedModuleIds': allowedModuleIds,
      'isSystem': isSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}