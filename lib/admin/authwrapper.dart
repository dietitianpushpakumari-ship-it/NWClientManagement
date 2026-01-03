import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🎯 IMPORTS (Update these paths if needed)
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';
import 'package:nutricare_client_management/admin/force_change_password_screen.dart';
import 'package:nutricare_client_management/login_screen.dart';

// ==================================================================
// 1. PROVIDERS (MUST BE DEFINED GLOBALLY)
// ==================================================================

// Listener for Firebase Auth changes (Logged In / Logged Out)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Logic to fetch user data from Firestore and restore the Session
final sessionRestorationProvider = FutureProvider.family<bool, User>((ref, user) async {
  try {
    // 1. If session is already loaded for this user, skip logic
    final currentSession = ref.read(adminSessionProvider);
    if (currentSession != null && currentSession.uid == user.uid) {
      return true;
    }

    // 2. Fetch User Profile from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('user_directory')
        .doc(user.email)
        .get();

    if (!doc.exists) {
      // Profile not found -> Access Denied
      return false;
    }

    final data = doc.data()!;

    // 3. Security Check: Is account disabled?
    if (data['isEnabled'] == false) return false;

    // 4. Create & Store Session
    final session = AdminSession(
      uid: user.uid,
      email: user.email ?? '',
      role: data['role'] ?? 'staff',
      tenantId: data['tenantId'], // Null for SuperAdmin
    );

    // Save to the state manager
    ref.read(adminSessionProvider.notifier).state = session;
    return true;

  } catch (e) {
    debugPrint("Session Restoration Error: $e");
    return false;
  }
});


// ==================================================================
// 2. THE AUTH WRAPPER WIDGET
// ==================================================================

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A. Watch Auth State (Is user logged in?)
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _LoadingScreen(),
      error: (e, s) => const LoginScreen(),
      data: (user) {
        // B. Not Logged In -> Show Login
        if (user == null) return const LoginScreen();

        // C. Logged In -> Restore Session (Fetch Role, TenantID, etc.)
        final sessionAsync = ref.watch(sessionRestorationProvider(user));

        return sessionAsync.when(
          loading: () => const _LoadingScreen(),
          error: (e, s) {
            // If restoration fails, logout for safety
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
          data: (isSuccess) {
            // If profile missing or disabled
            if (!isSuccess) {
              FirebaseAuth.instance.signOut(); // <--- ADD THIS
              return const LoginScreen();
            }

            // 🎯 1. GET SESSION DATA
            final session = ref.read(adminSessionProvider);

            // 👑 2. SUPER ADMIN BYPASS
            // If Super Admin, skip the forced password change check
            if (session?.role == 'superAdmin' || session?.isSuperAdmin == true) {
              return const AdminDashboardScreen();
            }

            // 🛡️ 3. REGULAR USERS: Check for "Force Change" Flag
            // We use StreamBuilder to listen for realtime updates
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('user_directory').doc(user.email).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _LoadingScreen();

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                // 🛑 CHECK: Does 'temp_password' still exist?
                if (data != null && data.containsKey('temp_password')) {
                  // YES -> Block access & Force Change
                  return const ForceChangePasswordScreen();
                }

                // NO -> Allow Access to Dashboard
                return const AdminDashboardScreen();
              },
            );
          },
        );
      },
    );
  }
}

// Simple Loading Indicator
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
  }
}