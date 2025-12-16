import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart'; // For DateUtils
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

import 'admin_profile_model.dart';

class StaffManagementService {

  final Ref _ref; // Store Ref to access dynamic providers
  StaffManagementService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🎯 CONFIG: Centralized Domain
  static const String _emailDomain = "@nutricarewellness.in";

  // ===========================================================================
  // 1. ONBOARDING (Admin Panel)
  // ===========================================================================
  Future<User?> login(String identifier, String password) async {
    String email = identifier.trim();

    // 🎯 LOGIC: Check if input is Mobile or Email
    if (!email.contains('@')) {
      // Assume Mobile: Clean and append domain
      final cleanMobile = email.replaceAll(" ", "");
      email = "$cleanMobile$_emailDomain";
    }
    // Else: Use the email as typed (e.g., "admin@gmail.com")

    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw Exception("Account not found.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Incorrect password.");
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future<String> onboardStaff({
    required String firstName,
    required String lastName,
    required String mobile,
    required String? altMobile,
    required String gender,
    required DateTime? dob,
    required String? aadhar,
    required String? pan,
    required String? address,
    required AdminRole role,
    required String designation,
    required List<String> qualifications,
    required List<String> specializations,
    required List<String> permissions,
    String? photoUrl,
  }) async {

    final String empId = await _generateEmployeeId();
    final String cleanMobile = mobile.trim().replaceAll(" ", "");

    // 🎯 FIX: Use Correct Domain
    final String shadowEmail = "$cleanMobile$_emailDomain";

    // 🎯 FIX: Initial Password is the Mobile Number
    final String autoPassword = cleanMobile;

    final Timestamp now = Timestamp.now();
    final String creatorUid = _auth.currentUser?.uid ?? 'system';

    FirebaseApp? tempApp;
    try {
      // Secondary app to create user without logging out admin
      final FirebaseOptions options = Firebase.app().options;
      tempApp = await Firebase.initializeApp(
        name: 'StaffOnboardTemp',
        options: options,
      );

      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
        email: shadowEmail,
        password: autoPassword,
      );

      final newStaff = AdminProfileModel(
        id: cred.user!.uid,
        email: shadowEmail,
        firstName: firstName,
        lastName: lastName,
        mobile: cleanMobile,
        alternateMobile: altMobile ?? '',
        gender: gender,
        dob: dob,

        aadharNumber: aadhar,
        panNumber: pan,
        address: address,

        employeeId: empId,
        role: role,
        isActive: true,

        designation: designation,
        qualifications: qualifications,
        specializations: specializations,
        permissions: permissions,

        dateOfJoining: DateTime.now(),
        photoUrl: photoUrl ?? '',
        companyName: "NutriCare",

        isDeleted: false,
        createdAt: now,
        updatedAt: now,
        createdBy: creatorUid,
        lastModifiedBy: creatorUid,
      );

      await _firestore.collection('admins').doc(cred.user!.uid).set(newStaff.toMap());

      return empId;

    } catch (e) {
      throw Exception("Onboarding Failed: $e");
    } finally {
      await tempApp?.delete();
    }
  }

  // ===========================================================================
  // 2. LOGIN (Mobile + Password)
  // ===========================================================================

  Future<User?> loginWithMobile(String mobile, String password) async {
    final cleanMobile = mobile.trim().replaceAll(" ", "");

    // 🎯 FIX: Use Correct Domain
    final email = "$cleanMobile$_emailDomain";

    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw Exception("Account not found for $mobile");
      } else if (e.code == 'wrong-password') {
        throw Exception("Incorrect password.");
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // Legacy support if needed
  Future<User?> loginWithEmployeeId(String empId, String password) async {
    // Try to resolve EmpID to Mobile via Firestore first?
    // Or assume user knows their mobile login.
    // For now, we deprecate this or redirect logic:
    throw Exception("Please use Mobile Number to login.");
  }

  // ===========================================================================
  // 3. ACTIVATION (Verify & Set New Password)
  // ===========================================================================

  Future<String?> verifyStaffIdentity({
    required String empId,
    required String mobile,
    required String lastName,
    required DateTime dob,
  }) async {
    try {
      final snap = await _firestore.collection('admins')
          .where('employeeId', isEqualTo: empId.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = doc.data();

      // A. Verify Mobile
      if ((data['mobile'] ?? '').trim() != mobile.trim()) return null;

      // B. Verify Last Name (Case Insensitive)
      if ((data['lastName'] ?? '').toString().toLowerCase() != lastName.trim().toLowerCase()) return null;

      // C. Verify DOB
      // Check 'dob' field first, fallback to 'dateOfJoining' if null (schema variation)
      Timestamp? storedTs = data['dob'];
      if (storedTs == null) return null;

      final storedDob = storedTs.toDate();
      if (!DateUtils.isSameDay(storedDob, dob)) return null;

      return doc.id; // Return UID for activation
    } catch (e) {
      debugPrint("Verification Error: $e");
      return null;
    }
  }

  Future<void> activateStaffAccount({
    required String uid,
    required String newPassword
  }) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    if (!doc.exists) throw Exception("User record not found.");

    // 🎯 Use Firestore data to construct credentials
    final String mobile = doc.data()?['mobile'] ?? '';
    final String expectedEmail = "$mobile$_emailDomain";

    try {
      // 1. Re-Auth with Default Creds (Mobile = Password)
      AuthCredential credential = EmailAuthProvider.credential(
          email: expectedEmail,
          password: newPassword // Default password is the mobile number
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

      // 2. Update Password
      if (userCred.user != null) {
        await userCred.user!.updatePassword(newPassword);
        await _auth.signOut(); // Force re-login
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Account already activated (Default password changed). Please Login normally.");
      }
      throw Exception("Activation Failed: ${e.message}");
    }
  }

  // ===========================================================================
  // 4. HELPERS (ID Gen & Master Data)
  // ===========================================================================

  Future<String> _generateEmployeeId() async {
    final docRef = _firestore.collection('configurations').doc('staff_counter');
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int currentCount = 1000;
      if (snapshot.exists) currentCount = snapshot.data()?['count'] ?? 1000;
      final newCount = currentCount + 1;
      transaction.set(docRef, {'count': newCount}, SetOptions(merge: true));
      return 'EMP-$newCount';
    });
  }

  Stream<List<String>> streamSpecializations() => _streamMasterList('specializations');
  Stream<List<String>> streamQualifications() => _streamMasterList('qualifications');
  Stream<List<String>> streamDesignations() => _streamMasterList('designations');

  Stream<List<String>> _streamMasterList(String field) {
    return _firestore.collection('configurations').doc('staff_master').snapshots().map((doc) {
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?[field] ?? []);
    });
  }

  Future<void> addSpecializationToMaster(String val) async => await _addToMasterArray('specializations', val);
  Future<void> addQualificationToMaster(String val) async => await _addToMasterArray('qualifications', val);
  Future<void> addDesignationToMaster(String val) async => await _addToMasterArray('designations', val);

  Future<void> _addToMasterArray(String field, String value) async {
    final docRef = _firestore.collection('configurations').doc('staff_master');
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({field: [value]});
    } else {
      await docRef.update({field: FieldValue.arrayUnion([value])});
    }
  }

  Future<void> deleteFromMaster(String field, String value) async {
    await _firestore.collection('configurations').doc('staff_master').update({
      field: FieldValue.arrayRemove([value])
    });
  }

  Future<void> updateInMaster(String field, String oldValue, String newValue) async {
    final docRef = _firestore.collection('configurations').doc('staff_master');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      List<String> list = List<String>.from(snapshot.data()?[field] ?? []);
      final index = list.indexOf(oldValue);
      if (index != -1) {
        list[index] = newValue;
        transaction.update(docRef, {field: list});
      }
    });
  }

  Future<List<AdminProfileModel>> getAllDietitians() async {
    final snap = await _firestore.collection('admins')
        .where('role', whereIn: ['dietitian', 'superAdmin']) // 🎯 Fixed
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => AdminProfileModel.fromFirestore(d)).toList();
  }

  Future<void> updateStaffProfile(AdminProfileModel staff) async {
    await _firestore.collection('admins').doc(staff.id).update(staff.toMap());
  }
  Stream<List<AdminProfileModel>> streamAllStaff() {
    return _firestore.collection('admins')
        .where('role', whereIn: ['dietitian', 'superAdmin']) // 🎯 Fixed
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AdminProfileModel.fromFirestore(d)).toList());
  }
}