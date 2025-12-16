import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TenantOnboardingService {
  final FirebaseFirestore _masterDb = FirebaseFirestore.instance;

  // Ensure this matches your console region
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  // --- 1. SAVE DRAFT (Safe Save) ---
  Future<void> saveDraftTenant(TenantModel config) async {
    try {
      // Force status to pending for drafts if not already active
      final data = config.toMap();
      if (config.status != TenantStatus.active) {
        data['status'] = TenantStatus.pending.name;
      }

      // Save to Master DB (Merge true to prevent overwriting existing fields if partial)
      await _masterDb.collection('tenants').doc(config.id).set(data, SetOptions(merge: true));
      print("✅ Draft saved safely for ${config.name}");
    } catch (e) {
      print("❌ Draft Save Failed: $e");
      throw Exception("Draft Save Failed: $e");
    }
  }

  // --- 2. TEST CONNECTION ---
  Future<bool> testConnection(TenantModel config) async {
    try {
      print("🔌 Verifying connection for ${config.projectId}...");

      // Auto-save draft before testing to prevent data loss on crash
      await saveDraftTenant(config);

      final callable = _functions.httpsCallable('verifyTenantConnection');
      await callable.call({
        'config': {
          'apiKey': config.apiKey,
          'projectId': config.projectId,
          'authDomain': "${config.projectId}.firebaseapp.com",
          'appId': config.appId,
        }
      });

      print("✅ Connection Verified!");
      return true;
    } catch (e) {
      print("❌ Connection Failed: $e");
      return false;
    }
  }

  // --- 3. ONBOARD & INVITE (The Risky Operation) ---
  Future<void> onboardAndInvite(TenantModel config, String tempPassword) async {
    // A. First, Save as Draft (Checkpoint)
    await saveDraftTenant(config);

    // B. Also save directory entry (so we can find them even if provisioning fails)
    await _masterDb.collection('user_directory').doc(config.ownerEmail).set({
      'tenant_id': config.id,
      'role': 'clinicAdmin',
      'status': 'pending_activation',
      'temp_password': tempPassword, // 🎯 SAVING IT HERE
      'is_password_changed': false,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // C. Call Cloud Function
    try {
      final callable = _functions.httpsCallable('provisionTenantAdmin');

      final nameParts = config.ownerName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Admin';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await callable.call({
        'config': {
          'apiKey': config.apiKey,
          'authDomain': "${config.projectId}.firebaseapp.com",
          'projectId': config.projectId,
          'storageBucket': config.storageBucket,
          'messagingSenderId': config.messagingSenderId,
          'appId': config.appId,
        },
        'email': config.ownerEmail,
        'password': tempPassword,
        'profile': {
          'firstName': firstName,
          'lastName': lastName,
          'mobile': config.ownerPhone,
          'companyName': config.name,
        }
      });

      // D. Success! Update status to Active
      await _masterDb.collection('tenants').doc(config.id).update({
        'status': TenantStatus.active.name,
        'invitedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Provisioning Complete.");

    } catch (e) {
      print("❌ Provisioning Failed: $e");
      // 🎯 CRITICAL FIX: DO NOT DELETE DATA HERE.
      // Leave it as 'pending' in Firestore so user can retry.
      throw Exception("Provisioning Failed (Data Saved as Draft): $e");
    }
  }

  // 4. Update Details (For simple edits)
  Future<void> updateTenantDetails(TenantModel tenant) async {
    await _masterDb.collection('tenants').doc(tenant.id).update(tenant.toMap());
  }

  // 📋 1. STREAM ALL TENANTS (For List Screen)
  Stream<List<TenantModel>> streamAllTenants() {
    return _masterDb.collection('tenants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TenantModel.fromMap(doc.id, doc.data()))
        .toList());
  }
}