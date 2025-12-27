import 'package:cloud_firestore/cloud_firestore.dart';

class RolePermissionModel {
  final String roleId;        // e.g., 'dietitian'
  final List<String> moduleIds; // e.g., ['diet_planning', 'chat']
  final Timestamp? lastUpdated;

  RolePermissionModel({
    required this.roleId,
    required this.moduleIds,
    this.lastUpdated,
  });

  factory RolePermissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RolePermissionModel(
      roleId: doc.id, // The Doc ID is the Role ID
      moduleIds: List<String>.from(data['moduleIds'] ?? []),
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moduleIds': moduleIds,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}