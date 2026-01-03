import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';
final adminAuthServiceProvider = Provider((ref) => AdminAuthService(ref));

class AdminAuthService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdminAuthService(this._ref);

  // 1. SIGN IN & BUILD SESSION
  Future<void> login({required String email, required String password}) async {
    try {
      // A. Auth with Firebase
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = cred.user;
      if (user == null) throw Exception("Authentication failed");

      // B. Fetch Profile from Central Directory
      DocumentSnapshot doc = await _db.collection('user_directory').doc(user.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception("User not found in directory. Contact Super Admin.");
      }

      final data = doc.data() as Map<String, dynamic>;

      // C. Create Session Object
      final session = AdminSession(
        uid: user.uid,
        email: email,
        role: data['role'] ?? 'staff', // e.g., 'superAdmin' or 'clinicAdmin'
        tenantId: data['tenantId'],    // 🔑 THE MOST IMPORTANT FIELD
      );

      // D. Save to Global State
      _ref.read(adminSessionProvider.notifier).state = session;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw Exception("Invalid credentials.");
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Login Error: $e");
    }
  }

  // 2. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    _ref.read(adminSessionProvider.notifier).state = null;
  }
}