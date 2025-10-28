import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/login_screen.dart';
import 'package:nutricare_client_management/screens/admin_home_Screen.dart';
// 🎯 ASSUME THIS IS YOUR LOGIN SCREEN PATH


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Connection state check
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner while checking the auth state.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User is logged in (Auto-login successful)
        if (snapshot.hasData && snapshot.data != null) {
          // Navigates to the main authenticated screen
          return const AdminDashboardScreen();
        }

        // 3. 🎯 FIX: User is NOT logged in or session expired
        // Redirect to the Login Screen
        return const LoginScreen();

        // ❌ The original code had: return const AdminHomeScreen();
      },
    );
  }
}