import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

// Service Injection
final adminProfileServiceProvider = Provider<AdminProfileService>((ref) {
  final db = ref.watch(firestoreProvider);
  final auth = ref.watch(authProvider);
  return AdminProfileService(db, auth);
});

// 🎯 THE FIXED PROVIDER
final currentAdminProvider = FutureProvider<AdminProfileModel?>((ref) async {
  final auth = ref.watch(authProvider);
  final user = auth.currentUser;

  if (user == null) return null;

  // 1. CHECK SESSION: Is this the Super Admin?
  final session = ref.read(adminSessionProvider);

  if (session?.isSuperAdmin == true) {
    // 🚀 GENERATE VIRTUAL PROFILE (No DB Call needed)
    return AdminProfileModel(
      id: user.uid,
      email: user.email ?? 'superadmin@nutricare.com',
      firstName: 'System',
      lastName: 'Super Admin',
      mobile: '',
      employeeId: 'SA-000',
      role: AdminRole.superAdmin, // 🔑 This gives "God Mode" access
      designation: 'Platform Owner',
      isActive: true,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      createdBy: 'system',
      lastModifiedBy: 'system',
      permissions: [], // hasAccess('any') returns true for superAdmin anyway
    );
  }

  // 2. NORMAL STAFF: Fetch from DB
  final service = ref.watch(adminProfileServiceProvider);
  return service.fetchAdminProfile();
});