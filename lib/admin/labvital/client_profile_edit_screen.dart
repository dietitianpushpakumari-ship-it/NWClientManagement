import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ClientProfileEditScreen extends ConsumerStatefulWidget {
  final ClientModel client;

  const ClientProfileEditScreen({super.key, required this.client});

  @override
  ConsumerState<ClientProfileEditScreen> createState() => _ClientProfileEditScreenState();
}

class _ClientProfileEditScreenState extends ConsumerState<ClientProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore get _firestore => ref.read(firestoreProvider);
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _altMobileCtrl;
  late TextEditingController _whatsappCtrl; // 🎯 NEW
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _ageCtrl;

  String? _gender;
  DateTime? _dob;
  File? _imageFile;
  String? _currentPhotoUrl;

  // 🎯 NEW STATE
  String _clientType = 'new';
  bool _isLoginActive = true;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final Map<String, String> _clientTypes = {
    'new': 'New / Pending',
    'active': 'Active Member',
    'one_time': 'One-Time Consult',
    'expired': 'Expired / Past'
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameCtrl = TextEditingController(text: widget.client.name);
    _mobileCtrl = TextEditingController(text: widget.client.mobile);
    _altMobileCtrl = TextEditingController(text: widget.client.altMobile ?? '');
    _whatsappCtrl = TextEditingController(text: widget.client.whatsappNumber ?? ''); // 🎯 Init
    _emailCtrl = TextEditingController(text: widget.client.email);
    _addressCtrl = TextEditingController(text: widget.client.address ?? '');
    _ageCtrl = TextEditingController(text: widget.client.age?.toString() ?? '');

    _gender = widget.client.gender;
    _dob = widget.client.dob;
    _currentPhotoUrl = widget.client.photoUrl;

    // 🎯 Init Status
    _clientType = widget.client.clientType;
    _isLoginActive = widget.client.status == 'Active';
  }

  // --- ACTIONS ---

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _ageCtrl.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentPhotoUrl;
    try {
      final ref = FirebaseStorage.instance.ref().child('client_profiles/${widget.client.id}.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? photoUrl = await _uploadImage();

      final updates = {
        'name': _nameCtrl.text.trim(),
        'altMobile': _altMobileCtrl.text.trim(),
        'whatsappNumber': _whatsappCtrl.text.trim(), // 🎯 Save
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gender': _gender,
        'dob': _dob != null ? Timestamp.fromDate(_dob!) : null,
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'photoUrl': photoUrl,
        'clientType': _clientType, // 🎯 Save
        'status': _isLoginActive ? 'Active' : 'Inactive', // 🎯 Save
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('clients').doc(widget.client.id).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
        Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // 1. Custom Header with Patient ID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20)),
                      ),
                      Column(
                        children: [
                          const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          // 🎯 SHOW PATIENT ID
                          Text("PID: ${widget.client.patientId ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(width: 40),
                    ],
                  ),
                ),

                // 2. Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Photo Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.15), width: 2)),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) as ImageProvider : null),
                                      child: (_imageFile == null && _currentPhotoUrl == null)
                                          ?  Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration:  BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 🎯 ACCOUNT STATUS & TYPE SECTION
                          _buildSectionLabel("Account & Security"),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Column(
                              children: [
                                // Client Type Dropdown
                                DropdownButtonFormField<String>(
                                  value: _clientType,
                                  decoration: InputDecoration(
                                    labelText: "Client Type",
                                    prefixIcon:  Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: _clientTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                                  onChanged: (v) => setState(() => _clientType = v!),
                                ),
                                const SizedBox(height: 16),
                                // Login Active Switch
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("App Login Access", style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(_isLoginActive ? "Allowed to login" : "Login blocked", style: TextStyle(color: _isLoginActive ? Colors.green : Colors.red, fontSize: 12)),
                                  value: _isLoginActive,
                                  activeColor: Colors.green,
                                  onChanged: (v) => setState(() => _isLoginActive = v),
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: _isLoginActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.lock_open, color: _isLoginActive ? Colors.green : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Personal Info
                          _buildSectionLabel("Personal Information"),
                          _buildPremiumTextField("Full Name", _nameCtrl, Icons.person),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _buildDatePicker()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdown()),
                          ]),
                          const SizedBox(height: 12),
                          _buildPremiumTextField("Age (Auto)", _ageCtrl, Icons.cake, isNumber: true, isEnabled: false),

                          const SizedBox(height: 24),

                          // Contact Info
                          _buildSectionLabel("Contact Details"),
                          _buildPremiumTextField("Primary Mobile", _mobileCtrl, Icons.phone, isEnabled: false),
                          const SizedBox(height: 12),
                          _buildPremiumTextField("Alternate Mobile", _altMobileCtrl, Icons.phone_android, isNumber: true),
                          const SizedBox(height: 12),
                          // 🎯 WHATSAPP FIELD
                          _buildPremiumTextField("WhatsApp Number", _whatsappCtrl, FontAwesomeIcons.whatsapp, isNumber: true),
                          const SizedBox(height: 12),
                          _buildPremiumTextField("Email Address", _emailCtrl, Icons.email),
                          const SizedBox(height: 12),
                          _buildPremiumTextField("Residential Address", _addressCtrl, Icons.location_on, maxLines: 3),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 5,
                                shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              ),
                              child: _isSaving
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildPremiumTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isEnabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: TextFormField(
        controller: ctrl,
        enabled: isEnabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: TextStyle(color: isEnabled ? Colors.black87 : Colors.grey.shade600, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: isEnabled ? Theme.of(context).colorScheme.primary.withOpacity(.5) : Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (v) => isEnabled && v!.isEmpty && label != "Email Address" ? "Required" : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary.withOpacity(.5), size: 20),
            const SizedBox(width: 12),
            Text(_dob == null ? "Select DOB" : DateFormat('dd/MM/yyyy').format(_dob!), style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          hint: const Text("Gender"),
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary.withOpacity(.5)),
          isExpanded: true,
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ),
    );
  }
}