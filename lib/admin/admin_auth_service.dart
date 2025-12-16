import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';

final adminAuthServiceProvider = Provider((ref) => AdminAuthService(ref));

class AdminAuthService {
  final Ref _ref;
  AdminAuthService(this._ref);

  // 🎯 1. LOOKUP TENANT (ID Validation)
  // This remains the same: finds the tenant ID based on the email.
  Future<TenantModel?> resolveTenant(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // Always check the MASTER DB (Default App) for directory
    final masterDb = FirebaseFirestore.instanceFor(app: Firebase.app());

    try {
      // A. Check Directory
      final userDoc = await masterDb.collection('user_directory').doc(cleanEmail).get();

      if (userDoc.exists) {
        final tenantId = userDoc.data()?['tenant_id'];

        // Special: If Super Admin on Live DB (No specific tenant)
        if (tenantId == 'live' || tenantId == null) return null;

        // B. Fetch Clinic Config
        final tenantDoc = await masterDb.collection('tenants').doc(tenantId).get();
        if (tenantDoc.exists) {
          return TenantModel.fromMap(tenantDoc.id, tenantDoc.data()!);
        }
      }
    } catch (e) {
      print("Tenant Lookup Failed: $e");
    }
    return null; // Default to Live/Super Admin
  }

  // 🎯 2. LOGIN (Validates ID setup, then validates Password)
  Future<User?> signIn(String email, String password) async {
    // 🎯 STEP 1: VALIDATE ID SETUP (Ensure Firebase App instance is ready)
    // We wait for the dynamic Firebase App creation/selection to complete.
    // This ensures the current Auth Provider is pointing to the correct project ID.
    try {
      await _ref.read(firebaseAppProvider.future);
    } catch (e) {
      // If the tenant ID was resolved but app creation failed (bad config), throw ID validation error
      throw Exception("Authentication setup failed. Tenant configuration error. $e");
    }

    // Now read the authProvider, which is guaranteed to be pointing to the correct tenant app
    final auth = _ref.read(authProvider);

    // 🎯 STEP 2: VALIDATE PASSWORD
    try {
      final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors cleanly
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Invalid email or password.");
      }
      // Re-throw any other error
      throw Exception("Login Failed: ${e.message ?? e.toString()}");
    } catch (e) {
      throw Exception("Login Failed: ${e.toString()}");
    }
  }
}