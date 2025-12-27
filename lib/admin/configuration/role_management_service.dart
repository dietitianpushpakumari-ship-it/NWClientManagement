import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/configuration/role_config_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

final roleManagementServiceProvider = Provider<RoleManagementService>((ref) {
  return RoleManagementService(ref.watch(firestoreProvider));
});

class RoleManagementService {
  final FirebaseFirestore _db;

  RoleManagementService(this._db);

  // 📂 Collection: tenants/{tenantId}/roles
  CollectionReference _getRoleCollection(String tenantId) {
    return _db.collection('tenants').doc(tenantId).collection('roles');
  }

  // 📋 Stream Roles
  Stream<List<RoleConfigModel>> streamRoles(String tenantId) {
    return _getRoleCollection(tenantId)
        .orderBy('isSystem', descending: true) // System roles first
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RoleConfigModel.fromFirestore(doc))
        .toList());
  }

  // 💾 Save Role (Create/Update)
  Future<void> saveRole(String tenantId, RoleConfigModel role) async {
    final docRef = role.id.isEmpty
        ? _getRoleCollection(tenantId).doc()
        : _getRoleCollection(tenantId).doc(role.id);

    await docRef.set(role.toMap(), SetOptions(merge: true));
  }

  // 🗑️ Delete Role
  Future<void> deleteRole(String tenantId, String roleId) async {
    await _getRoleCollection(tenantId).doc(roleId).delete();
  }

  // 🛠️ Initialize Default Roles (Helper)
  Future<void> ensureDefaultRoles(String tenantId) async {
    final col = _getRoleCollection(tenantId);
    final snap = await col.where('isSystem', isEqualTo: true).get();

    if (snap.docs.isEmpty) {
      // Create 'Admin' with all access implicitly handled elsewhere,
      // or explicit here. Let's create a base 'Dietitian' role.
      await col.add({
        'name': 'Dietitian',
        'allowedModuleIds': ['diet_planning', 'chat', 'appointments'],
        'isSystem': true,
      });
    }
  }
}