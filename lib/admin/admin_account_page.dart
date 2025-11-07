import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 🎯 ADJUST THESE IMPORTS TO YOUR PROJECT STRUCTURE
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';

// ----------------------------------------------------------------------
// --- MAIN WIDGET ---
// ----------------------------------------------------------------------

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminProfileService _service = AdminProfileService();

  // Get the current authenticated user. This can be null.
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Use the actual UID if available, otherwise use a fallback for dev/error state
  final String _adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'development_test_admin_uid';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 🛑 HANDLER FOR NULL USER: Cannot proceed without a logged-in user.
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account & Settings'),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text(
                  'Authentication Required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your current session is invalid or you are not logged in. Please restart the app or log in. UID: $_adminUid (Fallback)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- User is signed in ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile & Settings'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard & App'),
          ],
        ),
      ),
      body: SafeArea(child:StreamBuilder<AdminProfileModel>(
        stream: _service.streamAdminProfile(_adminUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading profile: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found. Please check Firestore.'));
          }

          final AdminProfileModel profile = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _ProfileDetailsTab(profile: profile, service: _service, adminUid: _adminUid),
              // Pass the current Firebase User object for security operations
              _SecurityLoginTab(loginId: profile.email, service: _service, currentUser: _currentUser),
              const _SettingsDashboardTab(),
            ],
          );
        },
      ),),
    );
  }
}

// ----------------------------------------------------------------------
// --- TAB 1: PROFILE DETAILS (EDITABLE) ---
// ----------------------------------------------------------------------

class _ProfileDetailsTab extends StatefulWidget {
  final AdminProfileModel profile;
  final AdminProfileService service;
  final String adminUid;

  const _ProfileDetailsTab({
    required this.profile,
    required this.service,
    required this.adminUid,
  });

  @override
  State<_ProfileDetailsTab> createState() => __ProfileDetailsTabState();
}

class __ProfileDetailsTabState extends State<_ProfileDetailsTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers matching the AdminProfileModel structure
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _designationController;
  late TextEditingController _companyController;
  late TextEditingController _regdNoController;
  late TextEditingController _companyEmailController; // 🎯 NEW CONTROLLER

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  // Update controllers when new stream data arrives and we are not actively editing
  @override
  void didUpdateWidget(_ProfileDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.profile.updatedAt != oldWidget.profile.updatedAt) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneController = TextEditingController(text: widget.profile.mobile);
    _altPhoneController = TextEditingController(text: widget.profile.alternateMobile); // 🎯 Initializing
    _websiteController = TextEditingController(text: widget.profile.website);         // 🎯 Initializing
    _addressController = TextEditingController(text: widget.profile.address);
    _designationController = TextEditingController(text: widget.profile.designation);
    _companyController = TextEditingController(text: widget.profile.companyName);
    _regdNoController = TextEditingController(text: widget.profile.regdNo);
    _companyEmailController = TextEditingController(text: widget.profile.companyEmail);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose(); // 🎯 Disposing
    _websiteController.dispose();  // 🎯 Disposing
    _addressController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _regdNoController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    final updateFields = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'mobile': _phoneController.text,
      'alternateMobile': _altPhoneController.text, // 🎯 Included in save map
      'website': _websiteController.text,         // 🎯 Included in save map
      'address': _addressController.text,
      'designation': _designationController.text,
      'companyName': _companyController.text,
      'regdNo': _regdNoController.text,
      'companyEmail': _companyEmailController.text,
    };

    try {
      await widget.service.updateAdminProfile(
        adminUid: widget.adminUid,
        updateFields: updateFields,
        modifierUid: widget.adminUid, // Current user is the modifier
      );
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType type = TextInputType.text, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: _isEditing && enabled, // Uses local enabled flag
          fillColor: (_isEditing && enabled) ? Colors.white : Colors.grey.shade100,
          filled: true,
        ),
        keyboardType: type,
        maxLines: maxLines,
        validator: (value) {
          if (label.contains('Name') && (value == null || value.isEmpty)) {
            return 'Please enter a name.';
          }
          if (label.contains('Phone') && (value == null || value.isEmpty)) {
            return 'Please enter a phone number.';
          }
          if (label.contains('Email') && value != null && value.isNotEmpty && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
            return 'Please enter a valid email address.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildReadOnlyField(String value, String label, {IconData icon = Icons.info_outline}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: const OutlineInputBorder(),
          fillColor: Colors.grey.shade100,
          filled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Profile Photo ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      widget.profile.photoUrl.isNotEmpty
                          ? widget.profile.photoUrl
                          : 'https://placehold.co/150x150/cccccc/333333?text=${widget.profile.firstName[0]}${widget.profile.lastName[0]}',
                    ),
                    child: _isEditing ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70) : null,
                  ),
                  TextButton.icon(
                    icon: Icon(_isEditing ? Icons.upload : Icons.person_pin),
                    label: Text(_isEditing ? 'Change Photo' : 'Profile Photo'),
                    onPressed: _isEditing ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo upload feature pending.')),
                      );
                    } : null,
                  ),
                  const Divider(),
                ],
              ),
            ),

            // --- Personal Details Section ---
            const _SectionHeader(title: 'Personal Details', icon: Icons.person_2),
            _buildReadOnlyField(widget.profile.email, 'Login Email (Cannot be changed here)', icon: Icons.email),

            Row(
              children: [
                Expanded(child: _buildTextField(_firstNameController, 'First Name')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_lastNameController, 'Last Name')),
              ],
            ),
            _buildTextField(_designationController, 'Designation'),
            _buildTextField(_phoneController, 'Primary Phone Number', type: TextInputType.phone),
            _buildTextField(_altPhoneController, 'Alternate Phone Number', type: TextInputType.phone),
            _buildTextField(_addressController, 'Address', maxLines: 3),

            const SizedBox(height: 20),

            // --- Business Details Section ---
            const _SectionHeader(title: 'Business Details', icon: Icons.business),
            _buildTextField(_companyController, 'Company/Clinic Name'),
            _buildTextField(_companyEmailController, 'Company Email', type: TextInputType.emailAddress), // 🎯 NEW FIELD
            _buildTextField(_regdNoController, 'Registration Number (Regd No)'),
            _buildTextField(_websiteController, 'Website URL', type: TextInputType.url),

            const SizedBox(height: 30),

            // --- Edit/Save Button ---
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_isEditing ? Icons.save : Icons.edit),
              label: Text(_isEditing ? 'Save Changes' : 'Edit Information'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green.shade700 : Colors.indigo.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isSaving ? null : () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),

            // --- Cancel Button (Only visible during editing) ---
            if (_isEditing && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      // Re-initialize to revert changes and exit editing
                      _initializeControllers();
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel Edit'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- TAB 2: SECURITY & LOGIN ---
// ----------------------------------------------------------------------

class _SecurityLoginTab extends StatefulWidget {
  final String loginId;
  final AdminProfileService service;
  final User? currentUser;

  const _SecurityLoginTab({
    required this.loginId,
    required this.service,
    required this.currentUser
  });

  @override
  State<_SecurityLoginTab> createState() => __SecurityLoginTabState();
}

class __SecurityLoginTabState extends State<_SecurityLoginTab> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate() || widget.currentUser == null) return;

    setState(() { _isChangingPassword = true; });

    try {
      // NOTE: Assumes widget.service.changePassword handles Firebase re-authentication
      await widget.service.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: ${e.toString().split(':').last.trim()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { _isChangingPassword = false; });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Check if Firebase Auth is available for security actions.
    final bool canChangePassword = widget.currentUser != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Login ID Section ---
          const _SectionHeader(title: 'Login Information', icon: Icons.badge),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Your Login ID (Email)'),
              subtitle: Text(widget.loginId, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 30),
          const _SectionHeader(title: 'Change Password', icon: Icons.vpn_key),

          // --- Change Password Form ---
          if (canChangePassword)
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  _buildPasswordField(_currentPasswordController, 'Current Password'),
                  _buildPasswordField(_newPasswordController, 'New Password', isNew: true),
                  _buildPasswordField(_confirmPasswordController, 'Confirm New Password', isConfirm: true),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: _isChangingPassword
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.update),
                    label: const Text('Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isChangingPassword ? null : _changePassword,
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Security features are unavailable because the current Firebase user session could not be verified.',
                style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {bool isNew = false, bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label.';
          }
          if (isNew && value.length < 6) {
            return 'Password must be at least 6 characters long.';
          }
          if (isConfirm && value != _newPasswordController.text) {
            return 'Passwords do not match.';
          }
          return null;
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- TAB 3: SETTINGS & PROFESSIONAL DASHBOARD ---
// ----------------------------------------------------------------------

class _SettingsDashboardTab extends StatelessWidget {
  const _SettingsDashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Professional Dashboard ---
          const _SectionHeader(title: 'Professional Dashboard', icon: Icons.analytics),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.leaderboard, color: Colors.green),
              title: const Text('View Analytics and Reports'),
              subtitle: const Text('Access client metrics, revenue, and consultation history.'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Professional Dashboard (Feature to be built).')),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // --- App Settings ---
          const _SectionHeader(title: 'Application Settings', icon: Icons.settings),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.color_lens, color: Colors.orange),
                  title: const Text('Theme Preference'),
                  subtitle: const Text('Light / Dark Mode selection.'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme Setting (Feature to be built).')),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.blue),
                  title: const Text('Notification Preferences'),
                  subtitle: const Text('Manage email and push notification settings.'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification Setting (Feature to be built).')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- COMMON SECTION HEADER ---
// ----------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade500, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }
}