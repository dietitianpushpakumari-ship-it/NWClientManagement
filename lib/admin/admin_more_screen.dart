import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';
// 🎯 Adjust this import path to your actual Admin Profile form/screen
// import 'package:nutricare_client_management/screens/admin_profile_edit_screen.dart';
// Use a placeholder for navigation for now
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';


class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  // Helper function to build the ListTiles
  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.indigo.shade600),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Placeholder: You need to fetch the current AdminProfileModel (e.g., from a Provider or FutureBuilder)

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Options'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // --- Profile Header ---

            const Divider(thickness: 1, indent: 16, endIndent: 16),


            // --- Core Account Options ---
            _buildOptionTile(
              context: context,
              title: 'My Profile',
              icon: Icons.account_circle,
              onTap: () {
                // 🎯 Navigate to Admin Profile Edit Screen
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAccountPage()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Admin Profile Edit')));
              },
            ),

            _buildOptionTile(
              context: context,
              title: 'Membership & Billing',
              icon: Icons.payments,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Billing Details')));
              },
            ),

            _buildOptionTile(
              context: context,
              title: 'User Management',
              icon: Icons.group,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to User Management Screen')));
              },
            ),


            // --- System & Legal Options ---
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('App & Security', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),

            _buildOptionTile(
              context: context,
              title: 'Settings',
              icon: Icons.settings,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to App Settings')));
              },
            ),

            _buildOptionTile(
              context: context,
              title: 'Security',
              icon: Icons.security,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Security Settings')));
              },
            ),

            _buildOptionTile(
              context: context,
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Privacy Policy link')));
              },
            ),

            // --- Logout ---
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // 🎯 Implement Firebase Logout here
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Logged Out!')));
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}