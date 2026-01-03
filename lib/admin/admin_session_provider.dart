import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSession {
  final String uid;
  final String email;
  final String role;       // 'superAdmin', 'clinicAdmin', 'dietitian'
  final String? tenantId;  // Null for Super Admin, 'tenant_123' for others

  AdminSession({
    required this.uid,
    required this.email,
    required this.role,
    this.tenantId,
  });

  bool get isSuperAdmin => role == 'superAdmin';
}

// Stores the current logged-in admin's context
final adminSessionProvider = StateProvider<AdminSession?>((ref) => null);