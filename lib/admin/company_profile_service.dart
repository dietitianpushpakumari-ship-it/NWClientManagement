// lib/admin/company_profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/company_profile_model.dart'; // 🎯 UPDATED IMPORT

class CompanyProfileService { // 🎯 RENAMED CLASS
  final FirebaseFirestore _firestore;
  final String _collection = 'tenant_profile'; // Dedicated collection
  final String _documentId = 'default_tenant_id'; // Singleton ID

  CompanyProfileService(this._firestore);

  /// Fetches the single company profile document.
  Future<CompanyProfileModel> fetchCompanyProfile() async { // 🎯 UPDATED METHOD NAME & RETURN TYPE
    try {
      final doc = await _firestore.collection(_collection).doc(_documentId).get();
      if (doc.exists) {
        return CompanyProfileModel.fromFirestore(doc); // 🎯 UPDATED MODEL
      }
      return CompanyProfileModel.empty(); // 🎯 UPDATED MODEL
    } catch (e) {
      throw Exception('Failed to fetch company profile: $e');
    }
  }

  /// Saves or updates the single company profile data.
  Future<void> saveCompanyProfile(Map<String, dynamic> data) async {
    // Ensure the data is written to the fixed document ID
    await _firestore.collection(_collection).doc(_documentId).set(
      data,
      SetOptions(merge: true),
    );
  }
}

// 🎯 Riverpod Provider for the Service (Registered in global_service_provider.dart)
final companyProfileServiceProvider = Provider((ref) { // 🎯 RENAMED PROVIDER
  final firestore = ref.read(firestoreProvider);
  return CompanyProfileService(firestore);
});