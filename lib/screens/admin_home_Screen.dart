import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';
import 'package:provider/provider.dart';

// Import your existing screens and the new AuthService

import '../helper/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // 0: Dashboard, 1: Settings, 2: App Config
  int _selectedIndex = 0;

  // List of main content pages
  final List<Widget> _pagesContent = [
    const Center(child: Text("General Settings Page Content")),
    const Center(child: Text("App Configuration Settings Page Content")),
  ];

  // --- Profile Action Methods ---

  /// Shows options for profile management (Change Image, Edit Profile, Change Password).
  void _showProfileOptions(BuildContext context, User? user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Change Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _handleChangeImage(context, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Admin Profile Name'),
                onTap: () {
                  Navigator.pop(context);
                  _handleEditProfile(context, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                onTap: () {
                  Navigator.pop(context);
                  // Ensure email is available before attempting password change
                  if (user.email != null) {
                    _handleChangePassword(context, user.email!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot change password, email not found.')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleChangeImage(BuildContext context, User user) async {
    // 1. Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecting and uploading image... (Placeholder)')),
    );

    try {
      // MOCK: Replace with a real upload, then update the profile URL
      const mockNewUrl = 'https://picsum.photos/200?random=1';
      //await Provider.of<AuthService>(context, listen: false).updateProfileImage(mockNewUrl);

      // The Consumer will handle the UI update via notifyListeners() in AuthService.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image update failed: ${e.toString()}')),
      );
    }
  }

  void _handleEditProfile(BuildContext context, User user) {
    String newName = user.displayName ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Admin Name'),
        content: TextFormField(
          initialValue: user.displayName,
          decoration: const InputDecoration(labelText: 'New Name'),
          onChanged: (value) => newName = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (newName.trim().isNotEmpty && newName != user.displayName) {
                try {
              //    await Provider.of<AuthService>(context, listen: false).updateProfileName(newName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile name updated!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Name update failed: ${e.toString()}')),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword(BuildContext context, String email) async {
    try {
   //   await Provider.of<AuthService>(context, listen: false).sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link: ${e.toString()}')),
      );
    }
  }

  // --- Drawer UI Component ---

  Widget _buildDrawer(BuildContext context) {
    // Consumer rebuilds the drawer header whenever AuthService calls notifyListeners()
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;

        // Determine profile details, using user data or sensible defaults
        final String name = user?.displayName ?? user?.email?.split('@').first ?? 'Guest Admin';
        final String email = user?.email ?? 'guest@app.com';
        final String? photoUrl = user?.photoURL;

        return Drawer(
          child: Column(
            children: <Widget>[
              // Header with Profile Image and Options (Tappable)
              GestureDetector(
                onTap: () => _showProfileOptions(context, user),
                child: UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade700,
                  ),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? Text(name[0].toUpperCase(), style: TextStyle(fontSize: 40, color: Colors.blueGrey.shade700))
                        : null,
                  ),
                ),
              ),

              // Navigation Items
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                selected: _selectedIndex == 0,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Master Setup Hub'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MasterSetupPage(),
                  ));
                },
              ),

              // Settings Items
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('General Settings'),
                selected: _selectedIndex == 1,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('App Configurational Settings'),
                selected: _selectedIndex == 2,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),

              const Spacer(),

              // Logout Button
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  authService.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Admin Dashboard';
    if (_selectedIndex == 1) title = 'General Settings';
    if (_selectedIndex == 2) title = 'App Configuration';

    return Scaffold(

      drawer: _buildDrawer(context),
      body: _pagesContent[_selectedIndex],
    );
  }
}