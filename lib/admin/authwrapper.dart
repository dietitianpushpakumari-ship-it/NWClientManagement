import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/login_screen.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

// 🎯 Provider that exposes the current User state dynamically
// It watches the authProvider, so when the tenant app changes, the stream automatically switches.
final userStreamProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges();
});


class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the dynamic user stream
    final userAsync = ref.watch(userStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      ),
      error: (err, stack) {
        // If the auth stream throws an error (e.g., token invalid), reset and show login
        print("Auth Stream Error: $err");
        return const LoginScreen();
      },
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        return const AdminDashboardScreen();
      },
    );
  }
}