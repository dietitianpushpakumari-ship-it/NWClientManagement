import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';


// 🎯 STUB: Assuming this structure from your admin_profile_model.dart import
enum UserRole { superAdmin, admin }

class AdminProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'admins';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- READ Operation (Stream) ---
  /// Streams the profile data for a specific admin UID.
  Stream<AdminProfileModel> streamAdminProfile(String adminUid) {
    return _firestore
        .collection(_collection)
        .doc(adminUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Handle case where profile doc doesn't exist yet
        throw Exception("Admin profile not found for UID: $adminUid");
      }
      return AdminProfileModel.fromFirestore(snapshot);
    });
  }

  // --- UPDATE Operation ---
  /// Updates the profile data in Firestore, leveraging the model's toMap().
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

      await _firestore
          .collection(_collection)
          .doc(adminUid)
          .update(finalUpdateFields);
    } catch (e) {
      print('Error updating admin profile: $e');
      throw Exception('Failed to update profile data: $e');
    }
  }

  // --- Password Change (Handled by Firebase Auth, not Firestore) ---
  /// Re-authenticates the user and updates their password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    try {
      // 1. Re-authenticate user with current credentials
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('The current password entered is incorrect.');
      }
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during password change.');
    }
  }

  Future<AdminProfileModel?> fetchAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(_collection) // 💡 ASSUMPTION: Your collection name is 'adminProfiles'
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        // 💡 ASSUMPTION: AdminProfileModel has a factory constructor `fromMap`
     //   return AdminProfileModel.fromMap(docSnapshot.data()!);
        return AdminProfileModel.fromDocument(docSnapshot);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching admin profile: $e");
      return null;
    }
  }
}