import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // Access your dynamic providers

// 🎯 PROVIDER: Automatically injects the correct Tenant DB & Auth
final companyConfigServiceProvider = Provider<CompanyConfigService>((ref) {
  final db = ref.watch(firestoreProvider); // Dynamic DB
  final auth = ref.watch(authProvider);    // Dynamic Auth
  return CompanyConfigService(db, auth);
});

class CompanyConfigService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // 🎯 Constructor Injection
  CompanyConfigService(this._db, this._auth);

  // 🎯 COLLECTION: 'company_settings'
  CollectionReference get _settingsCollection => _db.collection('company_settings');

  // 📦 Get Config for specific Tenant
  Stream<CompanyConfigModel> streamCompanyConfig(String tenantId) {
    return _settingsCollection
        .doc(tenantId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return CompanyConfigModel();
      }
      return CompanyConfigModel.fromFirestore(doc);
    });
  }

  // 💾 Update Modules (Tenant Admin Action)
  Future<void> updateEnabledModules(String tenantId, List<String> modules) async {
    try {
      final user = _auth.currentUser;

      // Upsert: Create if not exists, Merge if exists
      await _settingsCollection.doc(tenantId).set({
        'enabledModules': modules,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': user?.email ?? 'unknown',
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception("Failed to update company configuration: $e");
    }
  }

  // 🛠️ Initialize Default Settings
  Future<void> initializeSettings(String tenantId) async {
    final doc = await _settingsCollection.doc(tenantId).get();
    if (!doc.exists) {
      await _settingsCollection.doc(tenantId).set(CompanyConfigModel().toMap());
    }
  }
}