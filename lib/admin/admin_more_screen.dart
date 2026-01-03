import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';
import 'package:nutricare_client_management/admin/configuration/company_module_settings_screen.dart';
import 'package:nutricare_client_management/admin/configuration/role_policy_manager_Screen.dart';
import 'package:nutricare_client_management/admin/staff_management_screen.dart';
import 'package:nutricare_client_management/login_screen.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/screens/admin/flexible_availability_screen.dart';
// 🎯 New Import

import 'feed_management_screen.dart';

class AdminMoreScreen extends ConsumerStatefulWidget {
  const AdminMoreScreen({super.key});

  @override
  ConsumerState<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends ConsumerState<AdminMoreScreen> {
  bool _isLoadingConfig = false;

  // 🛠️ Helper: Resolve Tenant ID for the current user
// 🎯 NEW HELPER: Get Tenant Context from Session
  Future<Map<String, String>> _resolveTenantContext() async {
    // 1. Get Session
    final session = ref.read(adminSessionProvider);

    if (session == null || session.tenantId == null) {
      throw "No active session found. Please log in again.";
    }

    final String tenantId = session.tenantId!;

    // 2. Fetch Company Name (Optional, for UI)
    // We could cache this in the session to avoid this read, but this is safe for now.
    try {
      final doc = await FirebaseFirestore.instance.collection('tenants').doc(tenantId).get();
      final name = doc.data()?['name'] ?? 'Company Settings';
      return {'id': tenantId, 'name': name};
    } catch (e) {
      // Fallback if tenant doc read fails (e.g. permission issue)
      return {'id': tenantId, 'name': 'Settings'};
    }
  }
  // 🎯 Navigate to Module Settings
  Future<void> _navigateToModuleConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      final contextData = await _resolveTenantContext();
      if (contextData != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CompanyModuleSettingsScreen(tenantId: contextData['id']!, companyName: contextData['name']!),
        ));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingConfig = false);
    }
  }

  // 🎯 Navigate to Role Policies
  Future<void> _navigateToRolePolicy() async {
    setState(() => _isLoadingConfig = true);
    try {
      final contextData = await _resolveTenantContext();
      if (contextData != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RolePolicyManagerScreen(tenantId: contextData['id']!),
        ));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out?"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Log Out"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Glow
          Positioned(
            top: -100, right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)])),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Account Section
                        _buildSectionLabel("Account"),
                        _buildSectionContainer(
                          children: [
                            _buildOptionTile(
                              context,
                              "My Profile", "Manage personal details",
                              Icons.person_outline, Colors.blue,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountPage())),
                            ),
                            _buildDivider(),
                            _buildOptionTile(
                              context,
                              "Manage Team", "Staff & Roles",
                              Icons.groups, Colors.cyan,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
                            ),
                            _buildDivider(),
                            _buildOptionTile(
                              context,
                              "My Work Hours", "Set weekly availability",
                              Icons.arrow_forward_ios, Colors.indigo,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlexibleAvailabilityScreen())),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // App Settings Section
                        _buildSectionLabel("Application"),
                        _buildSectionContainer(
                          children: [
                            // 1. Module Config
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              onTap: _isLoadingConfig ? null : _navigateToModuleConfig,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                                child: _isLoadingConfig
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.extension, color: Colors.purple, size: 22),
                              ),
                              title: const Text("Module Configuration", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                              subtitle: const Text("Enable/Disable Features", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade300),
                            ),
                            _buildDivider(),

                            // 2. Role Permissions (🎯 New Entry)
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              onTap: _isLoadingConfig ? null : _navigateToRolePolicy,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.shield_outlined, color: Colors.indigo, size: 22),
                              ),
                              title: const Text("Access Policies", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                              subtitle: const Text("Map Roles to Modules", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade300),
                            ),
                            _buildDivider(),

                            _buildOptionTile(
                              context,
                              "Content & Marketing", "Feed & Library",
                              Icons.campaign, Colors.orange,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  FeedManagementScreen())),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text("LOG OUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              elevation: 5,
                              shadowColor: Colors.red.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text("Version 1.0.0", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Text("More Options", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(alignment: Alignment.centerLeft, child: Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2))),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(children: children),
    );
  }

  Widget _buildOptionTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade300),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 70, endIndent: 20);
  }
}