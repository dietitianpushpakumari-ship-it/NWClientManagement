import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🎯 Import Auth
import 'package:nutricare_client_management/admin/admin_account_page.dart';
import 'package:nutricare_client_management/admin/staff_management_screen.dart';
import 'package:nutricare_client_management/login_screen.dart'; // 🎯 Import Login Screen


import 'package:nutricare_client_management/scheduler/content_library_screen.dart';

import 'feed_management_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  // 🎯 LOGOUT FUNCTION
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
                // 2. Header
                _buildHeader(),

                // 3. Options List
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
                            // 🎯 Staff Management Link
                            _buildOptionTile(
                              context,
                              "Manage Team", "Staff & Roles",
                              Icons.groups, Colors.cyan,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // App Settings Section
                        _buildSectionLabel("Application"),
                        _buildSectionContainer(
                          children: [
                            _buildOptionTile(
                              context,
                              "Content & Marketing", "Feed & Library",
                              Icons.campaign, Colors.orange,
                                  () {
                                // Example linking to feed manager from settings too
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedManagementScreen()));
                              },
                            ),
                            _buildDivider(),
                            _buildOptionTile(
                              context,
                              "App Appearance", "Theme & Layout",
                              Icons.palette_outlined, Colors.teal,
                                  () {}, // Future: Link to AppAppearanceScreen
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // 🎯 LOGOUT BUTTON (WIRED UP)
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