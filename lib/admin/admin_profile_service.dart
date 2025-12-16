import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';

class AdminProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'admins';

  // 🎯 INJECT DEPENDENCIES (Instead of using .instance directly)
  AdminProfileService(this._firestore, this._auth);

  // --- READ Operation (Stream) ---
  Stream<AdminProfileModel> streamAdminProfile(String adminUid) {
    return _firestore
        .collection(_collection)
        .doc(adminUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception("Admin profile not found for UID: $adminUid");
      }
      return AdminProfileModel.fromFirestore(snapshot);
    });
  }

  // --- FETCH CURRENT USER ---
  Future<AdminProfileModel?> fetchAdminProfile() async {
    // 🎯 Use the injected _auth instance (which is connected to the Tenant)
    final user = _auth.currentUser;

    if (user == null) {
      print("⚠️ No user logged in on current auth instance.");
      return null;
    }

    try {
      // 🎯 Use the injected _firestore instance
      final docSnapshot = await _firestore.collection(_collection).doc(user.uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return AdminProfileModel.fromFirestore(docSnapshot);
      } else {
        print("⚠️ Profile document does not exist for uid: ${user.uid}");
        return null;
      }
    } catch (e) {
      print("Error fetching admin profile: $e");
      return null;
    }
  }

  // --- UPDATE Operation ---
  Future<void> updateAdminProfile({
    required String adminUid,
    required Map<String, dynamic> updateFields,
    required String modifierUid,
  }) async {
    try {
      final finalUpdateFields = {
        ...updateFields,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': modifierUid,
      };

      await _firestore.collection(_collection).doc(adminUid).update(finalUpdateFields);
    } catch (e) {
      print('Error updating admin profile: $e');
      throw Exception('Failed to update profile data: $e');
    }
  }
}