import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';

// =============================================================================
// 1. SERVICE PROVIDERS (Dependency Injection)
// =============================================================================

final staffManagementProvider = Provider<StaffManagementService>((ref) {
  return StaffManagementService();
});

final meetingServiceProvider = Provider<MeetingService>((ref) {
  return MeetingService();
});

final adminProfileServiceProvider = Provider<AdminProfileService>((ref) {
  return AdminProfileService();
});

// =============================================================================
// 2. DATA PROVIDERS (State)
// =============================================================================

// 🎯 2.1 CURRENT ADMIN PROFILE
final currentAdminProvider = FutureProvider<AdminProfileModel?>((ref) async {
  // Forces reload if user changes
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final service = ref.watch(adminProfileServiceProvider);
  return service.fetchAdminProfile();
});

// 🎯 2.2 ALL STAFF STREAM (The Missing Provider)
final allStaffStreamProvider = StreamProvider<List<AdminProfileModel>>((ref) {
  // You need to ensure getAllDietitians returns a Stream, not Future.
  // Or better, create a stream method in service.
  // Since your service currently has 'getAllDietitians' as Future, let's make a stream wrapper here or use FutureProvider.
  // Ideally, for "Manage Team" screen, we want a Stream.

  // Since StaffManagementService in Turn 60 didn't have a streamAllStaff,
  // let's implement it using snapshots here directly or assume service has it.
  // Recommendation: Add streamAllStaff() to StaffManagementService.

  // For now, using the service instance:
  return ref.watch(staffManagementProvider).streamAllStaff();
});

// 🎯 2.3 MASTER DATA STREAMS
final specializationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamSpecializations();
});

final qualificationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamQualifications();
});

final designationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamDesignations();
});