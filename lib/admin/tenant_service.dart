import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';

class TenantOnboardingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ⚠️ Ensure 'asia-south1' matches where you deployed your functions
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  // --- 🎯 MAIN ONBOARDING METHOD ---
  Future<void> onboardNewTenant({
    required TenantModel tenant,
    required String password,
  }) async {
    try {
      // 1. Save the Company Profile to Firestore (The "Business" Data)
      // We initially save it as 'pending' just in case the cloud function fails
      final Map<String, dynamic> tenantData = tenant.toMap();
      tenantData['status'] = 'pending';

      await _db.collection('tenants').doc(tenant.id).set(tenantData, SetOptions(merge: true));

      // 2. Call Cloud Function to Create the Admin User (The "Login" Data)
      final callable = _functions.httpsCallable('createClinicAdmin');

      await callable.call({
        'email': tenant.ownerEmail,
        'password': password,
        'tenantId': tenant.id,
        'firstName': tenant.ownerName.split(' ').first,
        'lastName': tenant.ownerName.split(' ').length > 1
            ? tenant.ownerName.split(' ').sublist(1).join(' ')
            : '',
      });

      // 3. Update Status to Active (since user creation succeeded)
      await _db.collection('tenants').doc(tenant.id).update({
        'status': 'active',
        'invitedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      // If the Cloud Function fails (e.g., email exists), we get a clean error here
      if (e is FirebaseFunctionsException) {
        throw Exception(e.message);
      }
      throw Exception("Onboarding Failed: $e");
    }
  }

  // --- STREAM LIST (For List Screen) ---
  Stream<List<TenantModel>> streamAllTenants() {
    return _db.collection('tenants')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TenantModel.fromFirestore(doc))
        .toList());
  }
}