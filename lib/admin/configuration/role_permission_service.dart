import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

// 🎯 Provider
final rolePermissionServiceProvider = Provider<RolePermissionService>((ref) {
  return RolePermissionService(ref.watch(firestoreProvider));
});

class RolePermissionService {
  final FirebaseFirestore _db;
  RolePermissionService(this._db);

  // 📂 Collection: company_settings/{tenantId}/role_permissions/{roleId}
  CollectionReference _getCollection(String tenantId) {
    return _db.collection('company_settings').doc(tenantId).collection('role_permissions');
  }

  // 📖 Stream Permissions for a specific Role
  Stream<RolePermissionModel> streamPermissionForRole(String tenantId, String roleId) {
    return _getCollection(tenantId).doc(roleId).snapshots().map((doc) {
      if (!doc.exists) return RolePermissionModel(roleId: roleId, moduleIds: []);
      return RolePermissionModel.fromFirestore(doc);
    });
  }

  // 💾 Save Permissions
  Future<void> updatePermissions(String tenantId, String roleId, List<String> modules) async {
    await _getCollection(tenantId).doc(roleId).set({
      'moduleIds': modules,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ⚡ Get All Permissions Once (For initialization/caching)
  Future<Map<String, List<String>>> getAllPermissions(String tenantId) async {
    final snap = await _getCollection(tenantId).get();
    final Map<String, List<String>> map = {};
    for (var doc in snap.docs) {
      map[doc.id] = List<String>.from(doc['moduleIds'] ?? []);
    }
    return map;
  }
}