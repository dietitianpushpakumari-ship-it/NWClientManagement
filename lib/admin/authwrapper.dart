import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    // Listen to auth changes but manage state manually to prevent flickering
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
          _isChecking = false;
        });
      }
    }, onError: (e) {
      // Handle stream errors gracefully
      if (mounted) {
        setState(() => _isChecking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show Loader ONLY during initial check
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    // 2. If User Exists -> Go to Dashboard
    if (_user != null) {
      return const AdminDashboardScreen();
    }

    // 3. No User -> Go to Login
    return const LoginScreen();
  }
}