import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';
import 'package:nutricare_client_management/image_compressor.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';

class DietitianOnboardingScreen extends ConsumerStatefulWidget {
  final AdminProfileModel? staffToEdit;
  const DietitianOnboardingScreen({super.key, this.staffToEdit});

  @override
  ConsumerState<DietitianOnboardingScreen> createState() => _DietitianOnboardingScreenState();
}

class _DietitianOnboardingScreenState extends ConsumerState<DietitianOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fnameCtrl = TextEditingController();
  final _lnameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _altMobileCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();

  // Dialog Input Controllers
  final _specInputCtrl = TextEditingController();
  final _qualInputCtrl = TextEditingController();
  final _desigInputCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();

  // State
  AdminRole _selectedRole = AdminRole.dietitian;
  String _gender = "Female";
  DateTime? _dob;

  List<String> _selectedQuals = [];
  List<String> _selectedSpecs = [];
  String? _selectedDesignation;

  // 🎯 NEW: Permissions
  final Map<String, String> _availablePermissions = {
    'onboard_client': 'Onboard New Clients',
    'manage_content': 'Content & Feed Manager',
    'view_financials': 'View Financial Ledger',
    'manage_schedule': 'Manage Availability',
    'manage_master': 'Master Data Setup',
    'view_analytics': 'View Analytics',
  };
  List<String> _selectedPermissions = ['onboard_client', 'manage_schedule']; // Defaults

  File? _photo;
  String? _existingPhotoUrl;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.staffToEdit != null) {
      _isEditing = true;
      _populateData(widget.staffToEdit!);
    }
  }

  void _populateData(AdminProfileModel staff) {
    _fnameCtrl.text = staff.firstName;
    _lnameCtrl.text = staff.lastName;
    _mobileCtrl.text = staff.mobile;
    _altMobileCtrl.text = staff.alternateMobile;
    _aadharCtrl.text = staff.aadharNumber ?? '';
    _panCtrl.text = staff.panNumber ?? '';
    _addressCtrl.text = staff.address ?? '';
    _empIdCtrl.text = staff.employeeId;
    _selectedDesignation = staff.designation.isNotEmpty ? staff.designation : null;
    //_emailCtrl.text = staff.email;
    _selectedRole = staff.role;
    _gender = staff.gender;
    _dob = staff.dob;
    _selectedQuals = List.from(staff.qualifications);
    _selectedSpecs = List.from(staff.specializations);
    _existingPhotoUrl = staff.photoUrl;
    _regNoController.text = staff.regdNo;
    _emailCtrl.text = staff.companyEmail;
    _empIdCtrl.text = staff.employeeId;


    // 🎯 Load Permissions
    _selectedPermissions = List.from(staff.permissions);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File? compressed = await ImageCompressor.compressAndGetFile(File(picked.path));
      setState(() => _photo = compressed ?? File(picked.path));
    }
  }

  // --- MASTER DATA HANDLERS ---
  Future<void> _addDesig() async {
    final String val = _desigInputCtrl.text.trim();

    if (val.isNotEmpty) {
      try {
        // 1. Check for local duplicates before calling the services
        // This prevents unnecessary network calls if the item is already selected
        if (_selectedDesignation == val) {
          _desigInputCtrl.clear();
          if (mounted) Navigator.pop(context);
          return;
        }

        // 2. Call the services to add to the Firestore master array
        await ref.read(staffManagementProvider).addDesignationToMaster(val);

        // 3. Update the local state immediately
        // This ensures the value is reflected in the UI without waiting for the stream
        setState(() {
          _selectedDesignation = val;
        });

        // 4. Cleanup UI
        _desigInputCtrl.clear();
        if (mounted) Navigator.pop(context);

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add designation: $e"))
          );
        }
      }
    }
  }
// lib/admin/dietitian_onboarding_screen.dart

  Future<void> _addQual() async {
    final val = _qualInputCtrl.text.trim();
    if (val.isNotEmpty) {
      // Prevent local duplicate selection before saving
      if (_selectedQuals.contains(val)) {
        _qualInputCtrl.clear();
        Navigator.pop(context);
        return;
      }

      await ref.read(staffManagementProvider).addQualificationToMaster(val);

      // Update local selection state immediately
      setState(() {
        _selectedQuals.add(val);
      });

      _qualInputCtrl.clear();
      if (mounted) Navigator.pop(context);
    }
  }



  Future<void> _addSpec() async {
    final val = _specInputCtrl.text.trim();
    if (val.isNotEmpty) {
      // Prevent local duplicate selection before saving
      if (_selectedSpecs.contains(val)) {
        _specInputCtrl.clear();
        Navigator.pop(context);
        return;
      }

      await ref.read(staffManagementProvider).addSpecializationToMaster(val);

      // Update local selection state immediately
      setState(() {
        _selectedSpecs.add(val);
      });

      _specInputCtrl.clear();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showAddDialog(String title, TextEditingController ctrl, VoidCallback onAdd) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text("Add $title"),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: title, border: const OutlineInputBorder())),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: onAdd, child: const Text("Add"))]
    ));
  }

  // --- SAVE ---
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _photo == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo is required"))); return; }
    if (_selectedDesignation == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Designation"))); return; }

    setState(() => _isSaving = true);
    try {
      String? photoUrl = _existingPhotoUrl;
      if (_photo != null) {
        final ref = FirebaseStorage.instance.ref().child('admin_photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_photo!);
        photoUrl = await ref.getDownloadURL();
      }

      if (_isEditing) {
        final updatedStaff = widget.staffToEdit!.copyWith(
          firstName: _fnameCtrl.text.trim(),
          lastName: _lnameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          alternateMobile: _altMobileCtrl.text.trim(),
          gender: _gender,
          dob: _dob,
          aadharNumber: _aadharCtrl.text.trim(),
          panNumber: _panCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          role: _selectedRole,
          designation: _selectedDesignation!,
          qualifications: _selectedQuals,
          specializations: _selectedSpecs,
          companyEmail: _emailCtrl.text.trim(),
          photoUrl: photoUrl,
          regdNo: _regNoController.text.trim(),
          permissions: _selectedPermissions,
          employeeId: _empIdCtrl.text.trim()// 🎯 Save permissions on edit
        );
        await ref.read(staffManagementProvider).updateStaffProfile(updatedStaff);
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green)); Navigator.pop(context); }
      } else {
        // 🎯 FIX: Pass permissions to onboardStaff
        final empId = await ref.read(staffManagementProvider).onboardStaff(
          firstName: _fnameCtrl.text.trim(),
          lastName: _lnameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          altMobile: _altMobileCtrl.text.trim(),
          gender: _gender,
          dob: _dob,
          aadhar: _aadharCtrl.text.trim(),
          pan: _panCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          role: _selectedRole,
          designation: _selectedDesignation!,
          qualifications: _selectedQuals,
          specializations: _selectedSpecs,
          photoUrl: photoUrl,
          regdNo: _regNoController.text.trim(),
          companyEmail: _emailCtrl.text.trim(),
          permissions: _selectedPermissions,
          employeeId: _empIdCtrl.text.trim()// 🎯 Passed here
        );
        if (mounted) _showSuccessDialog(empId);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog(String empId) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Text("🎉 Success"), content: Text("Staff Created.\nID: $empId\nPassword: Mobile Number"), actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("Done"))]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: Text(_isEditing ? "Edit Profile" : "Onboard Staff"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo
              // lib/admin/dietitian_onboarding_screen.dart

              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _photo != null
                        ? FileImage(_photo!) // Load local picked image
                        : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty // 🎯 Check for non-empty string
                        ? NetworkImage(_existingPhotoUrl!)
                        : null),
                    child: (_photo == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)) // 🎯 Also check here
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Identity
              _buildPremiumCard("Identity & Role", Icons.badge, Colors.indigo, [
                _buildDropdown("Role", _selectedRole, AdminRole.values, (v) => setState(() => _selectedRole = v!)),
                const SizedBox(height: 16),
                _buildTextField(_empIdCtrl, "Employee ID", Icons.badge_outlined),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildTextField(_fnameCtrl, "First Name", Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_lnameCtrl, "Last Name", Icons.person_outline)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildDropdown("Gender", _gender, ["Male", "Female", "Other"], (v) => setState(() => _gender = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePicker("DOB", _dob, (d) => setState(() => _dob = d))),
                ]),
                const SizedBox(width: 12),
                _buildTextField(_emailCtrl, "Official Email", Icons.email),
              ]),

              // 3. Contact
              _buildPremiumCard("Contact & KYC", Icons.contact_phone, Colors.blue, [
                _buildTextField(_mobileCtrl, "Primary Mobile", Icons.phone, isNum: true),
                const SizedBox(height: 16),
                _buildTextField(_altMobileCtrl, "Alt. Mobile", Icons.phone_android, isNum: true),
                const SizedBox(height: 16),
                _buildTextField(_addressCtrl, "Full Address", Icons.home, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(_aadharCtrl, "Aadhar Number", Icons.fingerprint, isNum: true),
                const SizedBox(height: 16),
                _buildTextField(_panCtrl, "PAN Number", Icons.credit_card),
              ]),

              // 4. Professional Profile Section
              _buildPremiumCard("Professional Profile", Icons.school, Colors.teal, [



                // lib/admin/dietitian_onboarding_screen.dart

// 🎯 DESIGNATION (Inside the build method)
                StreamBuilder<List<String>>(
                  stream: ref.watch(staffManagementProvider).streamDesignations(),
                  builder: (context, snapshot) {
                    final designations = snapshot.data ?? []; // 識 This list is live
                    return _buildSelectionTile(
                      label: "Designation",
                      value: (_selectedDesignation == null || _selectedDesignation!.isEmpty)
                          ? "Select Designation"
                          : _selectedDesignation!,
                      icon: Icons.badge_outlined,
                      onTap: () => _openSingleSelect(
                        "Designation",
                        designations, // 識 Pass the live list from the StreamBuilder
                        _selectedDesignation,
                            (res) => setState(() => _selectedDesignation = res),
                      ),
                    );
                  },
                ),


                const SizedBox(height: 20),
                _buildTextField(_regNoController, "Registration Number", Icons.app_registration),

                const SizedBox(height: 20),
                // lib/admin/dietitian_onboarding_screen.dart

                _buildSelectionTile(
                  label: "Qualifications",
                  value: _selectedQuals.isEmpty ? "Select Qualifications" : _selectedQuals.join(", "),
                  icon: Icons.school_outlined,
                  onTap: () => _openMultiSelect(
                    "Qualifications",
                    ref.read(staffManagementProvider).streamQualifications(), // 🎯 Pass Stream
                    _selectedQuals,
                        (res) => setState(() => _selectedQuals = res),
                  ),
                ),

                const SizedBox(height: 20),

                _buildSelectionTile(
                  label: "Specializations",
                  value: _selectedSpecs.isEmpty ? "Select Specializations" : _selectedSpecs.join(", "),
                  icon: Icons.star_outline,
                  onTap: () => _openMultiSelect(
                    "Specializations",
                    ref.read(staffManagementProvider).streamSpecializations(), // 🎯 Pass Stream
                    _selectedSpecs,
                        (res) => setState(() => _selectedSpecs = res),
                  ),
                ),
                // DESIGNATION (Keeping single select as is)

                const SizedBox(height: 20),


              ]),


              // 🎯 5. NEW: ACCESS PERMISSIONS
              _buildPremiumCard("Access Control", Icons.lock_open, Colors.redAccent, [
                const Text("Select allowed modules:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                ..._availablePermissions.entries.map((e) {
                  return CheckboxListTile(
                    title: Text(e.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _selectedPermissions.contains(e.key),
                    activeColor: Colors.redAccent,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPermissions.add(e.key);
                        } else {
                          _selectedPermissions.remove(e.key);
                        }
                      });
                    },
                  );
                }),
              ]),

              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? "UPDATE PROFILE" : "ONBOARD STAFF", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterHeader(String title, Stream<List<String>> stream, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal), onPressed: onAdd, tooltip: "Add New"),
      ],
    );
  }

  Widget _buildPremiumCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)], border: Border.all(color: color.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color))]), const SizedBox(height: 16), ...children]));
  }
  Widget _buildTextField(TextEditingController c, String label, IconData icon, {bool isNum = false, int maxLines = 1}) {
    return TextFormField(controller: c, keyboardType: isNum ? TextInputType.phone : TextInputType.text, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18, color: Colors.grey), border: const OutlineInputBorder(), filled: true, fillColor: Colors.white), validator: (v) => v!.isEmpty ? "Required" : null);
  }
  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(value: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white), items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString().split('.').last.toUpperCase()))).toList(), onChanged: onChanged);
  }
  Widget _buildDatePicker(String label, DateTime? val, ValueChanged<DateTime> onSelect) {
    return InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime(1990), firstDate: DateTime(1950), lastDate: DateTime.now()); if (d != null) onSelect(d); }, child: InputDecorator(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white), child: Text(val != null ? DateFormat('dd/MM/yyyy').format(val) : "Select")));
  }

  // Helper to launch your existing Generic Dialog
// lib/admin/dietitian_onboarding_screen.dart

  // lib/admin/dietitian_onboarding_screen.dart

  // lib/admin/dietitian_onboarding_screen.dart

  void _openMultiSelect(
      String title,
      Stream<List<String>> itemStream, // 🎯 Pass the stream directly
      List<String> currentSelections,
      Function(List<String>) onUpdate,
      ) async {
    final List<String>? results = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<List<String>>(
        stream: itemStream, // 🎯 Re-run builder whenever Firestore changes
        builder: (context, snapshot) {
          return GenericMultiSelectDialog(
            title: title,
            items: snapshot.data ?? [], // 🎯 Live data from stream
            itemNameIdMap: const {},
            initialSelectedItems: currentSelections,
            onAddMaster: () {
              if (title == "Qualifications") {
                _showAddDialog("Qualification", _qualInputCtrl, _addQual);
              } else if (title == "Specializations") {
                _showAddDialog("Specialization", _specInputCtrl, _addSpec);
              }
            },
          );
        },
      ),
    );

    if (results != null) onUpdate(results);
  }
  Widget _buildSelectionTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.teal),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  // lib/admin/dietitian_onboarding_screen.dart

  void _openSingleSelect(
      String title,
      List<String> items,
      String? currentValue,
      Function(String?) onUpdate,
      ) async {
    // Use showModalBottomSheet as required by your GenericMultiSelectDialog layout
    final List<String>? results = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true, // Allows the 0.9 height container
      backgroundColor: Colors.transparent,
      builder: (context) => GenericMultiSelectDialog(
        title: title,
        items: items,
        itemNameIdMap: const {}, // Not currently used for UI display
        initialSelectedItems: currentValue != null ? [currentValue] : [],
        singleSelect: true, // 🎯 Key fix for single selection logic
        onAddMaster: () {
          // Trigger your existing designation add logic
          _showAddDialog("Designation", _desigInputCtrl, _addDesig);
        },
      ),
    );

    if (results != null) {
      // Return the first item if list is not empty, otherwise null
      onUpdate(results.isNotEmpty ? results.first : null);
    }
  }
}