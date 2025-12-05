import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/client_profile_model.dart';
import 'package:nutricare_client_management/admin/user_auth_meta_data_model.dart';
//note: PatientIdService is NOT used here, but in the Consultation form

// --- 1. User Role Definitions ---
enum UserRole {
  superAdmin,
  admin,
  client,
}

const String _clientAuthDomain = '@nutricare-client.app';

UserRole stringToRole(dynamic roleString) {
  if (roleString is String) {
    if (roleString == UserRole.superAdmin.name) return UserRole.superAdmin;
    if (roleString == UserRole.admin.name) return UserRole.admin;
  }
  return UserRole.client;
}

class UserManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _authMetadataCollection = 'authMetadata';
  static const String _adminCollection = 'admins';
  static const String _clientCollection = 'clients';

  // ----------------------------------------------------------------------
  // A. SUPER ADMIN INITIALIZATION
  // ----------------------------------------------------------------------

  Future<void> initializeSuperAdmin() async {
    const String superAdminEmail = 'superadmin@nutricare.com';
    const String superAdminPassword = 'StrongPassword123!';

    final querySnapshot = await _firestore.collection(_adminCollection)
        .where('role', isEqualTo: UserRole.superAdmin.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      try {
        UserCredential userCredential;
        // Try to create or sign in if already created
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: superAdminEmail,
            password: superAdminPassword,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            userCredential = await _auth.signInWithEmailAndPassword(
              email: superAdminEmail,
              password: superAdminPassword,
            );
          } else {
            rethrow;
          }
        }

        final User? user = userCredential.user;
        if (user != null) {
          final now = Timestamp.now();
          // 1. Create Admin Profile
          final superAdminProfile = AdminProfileModel(
            id: user.uid,
            email: superAdminEmail,
            firstName: 'Super',
            lastName: 'Admin',
            role: AdminRole.superAdmin,
            createdAt: now,
            updatedAt: now,
            createdBy: 'system',
            lastModifiedBy: 'system',
            companyName: '',
            designation: '',
            mobile: '',
            address: '', employeeId: '',
          );
          await _firestore.collection(_adminCollection).doc(user.uid).set(superAdminProfile.toMap());

          // 2. Create Auth Metadata
          final superAdminMetadata = UserAuthMetadataModel(
            id: user.uid,
            profileCollection: _adminCollection,
            lastPasswordChange: now,
          );
          await _firestore.collection(_authMetadataCollection).doc(user.uid).set(superAdminMetadata.toMap());

          await _auth.signOut();
        }
      } catch (e) {
        print('FATAL ERROR during Super Admin initialization: $e');
      }
    }
  }

  // ----------------------------------------------------------------------
  // B. ADMIN LOGIN VALIDATION
  // ----------------------------------------------------------------------

  Future<AdminProfileModel?> validateAdminLogin(String uid) async {
    try {
      final authMetadataDoc = await _firestore.collection(_authMetadataCollection).doc(uid).get();
      if (!authMetadataDoc.exists) return null;

      final metadata = UserAuthMetadataModel.fromFirestore(authMetadataDoc);
      // ... (Rest of status checks omitted for brevity) ...

      if (metadata.profileCollection != _adminCollection) {
        await _auth.signOut();
        return null;
      }

      final adminProfileDoc = await _firestore.collection(_adminCollection).doc(uid).get();
      if (!adminProfileDoc.exists) return null;

      final profile = AdminProfileModel.fromFirestore(adminProfileDoc);

      // Update last login time
      await _firestore.collection(_authMetadataCollection).doc(uid).update({
        'lastLoginDetails': FieldValue.serverTimestamp(),
        'failedLoginAttempts': 0,
      });

      return profile;

    } catch (e) {
      await _auth.signOut();
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // C. USER CREATION (Admin/Super Admin)
  // ----------------------------------------------------------------------

  Future<void> createAdminUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AdminRole role,
    required String creatorUid,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User newUser = userCredential.user!;
    final now = Timestamp.now();

    // 2. Write AdminProfileModel
    final adminProfile = AdminProfileModel(
      id: newUser.uid, email: email, firstName: firstName, lastName: lastName, role: role,
      createdAt: now, updatedAt: now, createdBy: creatorUid, lastModifiedBy: creatorUid,
      companyName: '',
      designation: '',
      mobile: '',
      address: '', gender: '', employeeId: '',
    );
    await _firestore.collection(_adminCollection).doc(newUser.uid).set(adminProfile.toMap());

    // 3. Write UserAuthMetadataModel
    final authMetadata = UserAuthMetadataModel(
      id: newUser.uid, profileCollection: _adminCollection, lastPasswordChange: now,
    );
    await _firestore.collection(_authMetadataCollection).doc(newUser.uid).set(authMetadata.toMap());
  }

  // NOTE: createClientUser is now only used for the UPGRADE/PROMOTION step
  Future<void> createClientUser({
    required String loginId,
    required String password,
    required ClientProfileModel unauthenticatedProfile, // Profile data
    required String creatorUid, // Audit field
  }) async {
    final String authEmail = '$loginId$_clientAuthDomain';

    // 1. Create user in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: authEmail,
      password: password,
    );
    final User newUser = userCredential.user!;
    final now = Timestamp.now();

    // 2. Write permanent ClientProfileModel (using data from consultation)
    final authenticatedProfile = ClientProfileModel(
      id: newUser.uid,
      patientId: unauthenticatedProfile.patientId,
      email: authEmail,
      loginId: loginId,
      clientName: unauthenticatedProfile.clientName,
      age: unauthenticatedProfile.age,
      mobileNumber: unauthenticatedProfile.mobileNumber,
      gender: unauthenticatedProfile.gender,
      address: unauthenticatedProfile.address,
      dateOfBirth: unauthenticatedProfile.dateOfBirth,
      createdAt: unauthenticatedProfile.createdAt, // Retain original creation time
      updatedAt: now,
      createdBy: unauthenticatedProfile.createdBy,
      lastModifiedBy: creatorUid,
    );
    await _firestore.collection(_clientCollection).doc(newUser.uid).set(authenticatedProfile.toMap());

    // 3. Write UserAuthMetadataModel
    final authMetadata = UserAuthMetadataModel(
      id: newUser.uid, profileCollection: _clientCollection, lastPasswordChange: now,
    );
    await _firestore.collection(_authMetadataCollection).doc(newUser.uid).set(authMetadata.toMap());

    // 4. Delete temporary record (optional, but good practice)
    await _firestore.collection('unauthenticatedClients').doc(unauthenticatedProfile.id).delete();
  }

  // ----------------------------------------------------------------------
  // D. DEACTIVATION/SOFT-DELETE LOGIC (Same logic applies to temp/permanent records)
  // ----------------------------------------------------------------------

  Future<void> deactivateUser({
    required String targetUid,
    required String collectionName, // e.g., 'clients', 'admins', or 'unauthenticatedClients'
    required String adminUid,
    required String reason,
  }) async {
    final now = FieldValue.serverTimestamp();

    if (collectionName != 'unauthenticatedClients') {
      // 1. Disable Auth Login (Only if it's an authenticated client/admin)
      await _firestore.collection(_authMetadataCollection).doc(targetUid).update({
        'isLoginDisabled': true, 'disabledBy': adminUid, 'disabledReason': reason, 'updatedAt': now,
      });
    }

    // 2. Soft-Delete Profile
    await _firestore.collection(collectionName).doc(targetUid).update({
      'isDeleted': true,
      'lastModifiedBy': adminUid,
      'updatedAt': now,
    });
  }
}