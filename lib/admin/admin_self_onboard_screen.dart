import 'package:flutter/material.dart';

import 'admin_profile_model.dart';
import 'admin_profile_service.dart';

class AdminSelfOnboardScreen extends StatefulWidget {
  final AdminProfileModel currentProfile;
  const AdminSelfOnboardScreen({super.key, required this.currentProfile});

  @override
  State<AdminSelfOnboardScreen> createState() => _AdminSelfOnboardScreenState();
}

class _AdminSelfOnboardScreenState extends State<AdminSelfOnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _designationCtrl;
  late TextEditingController _qualCtrl;
  late TextEditingController _bioCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _designationCtrl = TextEditingController(text: widget.currentProfile.designation);
    // Handle list to string conversion for simple editing
    _qualCtrl = TextEditingController(text: widget.currentProfile.qualifications.join(', '));
    _bioCtrl = TextEditingController(text: widget.currentProfile.bio);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Parse qualifications back to list
      final qualList = _qualCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      await AdminProfileService().updateAdminProfile(
        adminUid: widget.currentProfile.id,
        updateFields: {
          'designation': _designationCtrl.text,
          'qualifications': qualList,
          'bio': _bioCtrl.text,
          'isActive': true,
          // 🎯 CRITICAL FIX: Do NOT overwrite 'role' here.
          // Keep the existing role (SuperAdmin).
        },
        modifierUid: widget.currentProfile.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated! You are now set up as a Coach.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup My Coach Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("To accept appointments, please complete your professional profile.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextFormField(controller: _designationCtrl, decoration: const InputDecoration(labelText: "Designation", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _qualCtrl, decoration: const InputDecoration(labelText: "Qualifications (comma separated)", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Bio / About Me", border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const CircularProgressIndicator() : const Text("SAVE & GO LIVE")))
            ],
          ),
        ),
      ),
    );
  }
}