// user_management_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. MUST extend ChangeNotifier
class UserManageService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 2. The observable state property
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Constructor/Initializer
  UserManagementService() {
    // 3. LISTEN to FirebaseAuth changes and update the local state
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;

      // 4. VITAL: Notify all listeners (including AuthWrapper) to rebuild!
      notifyListeners();
    });
  }

  // Example Login Method
  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // NOTE: The authStateChanges listener above will handle setting _currentUser
      // and calling notifyListeners() for you!
    } catch (e) {
      // Handle error
    }
  }
}