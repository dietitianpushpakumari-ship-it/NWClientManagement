import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  State<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

// Inside _ForceChangePasswordScreenState
  Future<void> _changePassword(WidgetRef ref) async { // Add ref if using Consumer
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Update Auth Password
      await user.updatePassword(_passCtrl.text.trim());

      // 2. Clear the temporary flag in Firestore
      await FirebaseFirestore.instance
          .collection('user_directory')
          .doc(user.email)
          .update({
        'temp_password': FieldValue.delete(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 🎯 3. REFRESH THE SESSION PROVIDER
      // Fetch the fresh document to re-populate the session
      final doc = await FirebaseFirestore.instance
          .collection('user_directory')
          .doc(user.email)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        ref.read(adminSessionProvider.notifier).state = AdminSession(
          uid: user.uid,
          email: user.email ?? '',
          role: data['role'] ?? 'staff',
          tenantId: data['tenantId'],
        );
      }

      if (mounted) {
        // Navigate to Dashboard - the provider is now populated!
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen())
        );
      }
    } catch (e) {
      // Handle error...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Update Required"), automaticallyImplyLeading: false), // No Back Button
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_update_warning_rounded, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "Change Default Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "For your security, you must change the system-generated password before accessing the dashboard.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (v) => (v!.length < 6) ? "Minimum 6 characters required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v != _passCtrl.text ? "Passwords do not match" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Consumer( // 🎯 Wrap with Consumer to get 'ref'
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _changePassword(ref), // 🎯 Call with ref inside an anonymous function
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("UPDATE PASSWORD & LOGIN"),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(), // Allow them to logout if they want
                  child: const Text("Log Out", style: TextStyle(color: Colors.grey)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}