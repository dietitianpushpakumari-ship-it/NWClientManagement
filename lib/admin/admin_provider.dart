import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep this import for Type definition
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // 🎯 Import Database Provider
import 'package:nutricare_client_management/admin/meeting_service_old.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';

// =============================================================================
// 1. SERVICE PROVIDERS (Dependency Injection)
// =============================================================================



// 🎯 UPDATED: Inject Dynamic DB & Auth
final adminProfileServiceProvider = Provider<AdminProfileService>((ref) {
  final db = ref.watch(firestoreProvider); // Connects to Tenant DB
  final auth = ref.watch(authProvider);    // Connects to Tenant Auth
  return AdminProfileService(db, auth);
});

// =============================================================================
// 2. DATA PROVIDERS (State)
// =============================================================================

// 🎯 2.1 CURRENT ADMIN PROFILE
final currentAdminProvider = FutureProvider<AdminProfileModel?>((ref) async {
  // 🎯 FIX: Watch the Dynamic Auth Provider to check login status
  final auth = ref.watch(authProvider);
  final user = auth.currentUser;

  if (user == null) return null;

  // Use the services which is already connected to the correct DB
  final service = ref.watch(adminProfileServiceProvider);
  return service.fetchAdminProfile();
});

// 🎯 2.2 ALL STAFF STREAM
