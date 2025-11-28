import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminProfileService _service = AdminProfileService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
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
    if (_currentUser == null) return _buildUnauthView();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
              top: -100, right: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // 1. Custom Header with TabBar
                _buildHeader(),

                // 2. Tab Views
                Expanded(
                  child: StreamBuilder<AdminProfileModel>(
                    stream: _service.streamAdminProfile(_adminUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                      if (!snapshot.hasData) return const Center(child: Text('No profile data found.'));

                      final profile = snapshot.data!;
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _ProfileDetailsTab(profile: profile, service: _service, adminUid: _adminUid),
                          _SecurityLoginTab(loginId: profile.email, service: _service, currentUser: _currentUser),
                          const _SettingsDashboardTab(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
                    const SizedBox(width: 16),
                    const Text("Account & Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Profile', icon: Icon(Icons.person_outline, size: 20)),
                  Tab(text: 'Security', icon: Icon(Icons.lock_outline, size: 20)),
                  Tab(text: 'App Info', icon: Icon(Icons.info_outline, size: 20)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthView() {
    return Scaffold(
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock, size: 64, color: Colors.red), const SizedBox(height: 20), const Text("Authentication Required")])),
    );
  }
}

// ... [Keep _ProfileDetailsTab, _SecurityLoginTab, _SettingsDashboardTab, _SectionHeader classes unchanged from previous version, just ensuring they use the new styling hooks if any] ...
// (For brevity, assuming the child tab widgets code from previous context is reused here. They are compatible.)
class _ProfileDetailsTab extends StatefulWidget {
  final AdminProfileModel profile;
  final AdminProfileService service;
  final String adminUid;
  const _ProfileDetailsTab({required this.profile, required this.service, required this.adminUid});
  @override
  State<_ProfileDetailsTab> createState() => __ProfileDetailsTabState();
}
class __ProfileDetailsTabState extends State<_ProfileDetailsTab> {
  // ... (Copy existing logic for _ProfileDetailsTab)
  // Ensure build returns SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(...))
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabled: _isEditing && enabled, // Uses local enabled flag
          fillColor: (_isEditing && enabled) ? Colors.white : Colors.grey.shade100,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      widget.profile.photoUrl.isNotEmpty
                          ? widget.profile.photoUrl
                          : 'https://placehold.co/150x150/cccccc/333333?text=${widget.profile.firstName[0]}',
                    ),
                    child: _isEditing ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70) : null,
                  ),
                  TextButton.icon(
                    icon: Icon(_isEditing ? Icons.upload : Icons.person_pin),
                    label: Text(_isEditing ? 'Change Photo' : 'Profile Photo'),
                    onPressed: _isEditing ? () {} : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_firstNameController, 'First Name'),
            _buildTextField(_lastNameController, 'Last Name'),
            _buildTextField(_phoneController, 'Phone'),
            _buildTextField(_companyEmailController, 'Company Email'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                label: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.green : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_isEditing) _saveProfile();
                  else setState(() => _isEditing = true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityLoginTab extends StatelessWidget {
  final String loginId;
  final AdminProfileService service;
  final User? currentUser;
  const _SecurityLoginTab({required this.loginId, required this.service, required this.currentUser});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: const Text("Login Email"),
              subtitle: Text(loginId, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {}, // Implement change password dialog
              icon: const Icon(Icons.lock_reset),
              label: const Text("Change Password"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          )
        ],
      ),
    );
  }
}

class _SettingsDashboardTab extends StatelessWidget {
  const _SettingsDashboardTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("App Settings Placeholder"));
  }
}