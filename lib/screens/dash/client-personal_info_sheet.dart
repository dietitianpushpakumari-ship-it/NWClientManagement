import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// =============================================================================
// 1. PERSONAL & CONTACT INFO SHEET
// =============================================================================
class ClientPersonalInfoSheet extends StatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onSave;

  const ClientPersonalInfoSheet({super.key, required this.client, required this.onSave});

  @override
  State<ClientPersonalInfoSheet> createState() => _ClientPersonalInfoSheetState();
}

class _ClientPersonalInfoSheetState extends State<ClientPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _altMobileCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _ageCtrl;

  String? _gender;
  DateTime? _dob;
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client.name);
    _mobileCtrl = TextEditingController(text: widget.client.mobile);
    _altMobileCtrl = TextEditingController(text: widget.client.altMobile ?? '');
    _whatsappCtrl = TextEditingController(text: widget.client.whatsappNumber ?? '');
    _emailCtrl = TextEditingController(text: widget.client.email);
    _addressCtrl = TextEditingController(text: widget.client.address ?? '');
    _ageCtrl = TextEditingController(text: widget.client.age?.toString() ?? '');
    _gender = widget.client.gender;
    _dob = widget.client.dob;
    _currentPhotoUrl = widget.client.photoUrl;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? photoUrl = await _uploadImage();
      final updates = {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'altMobile': _altMobileCtrl.text.trim(),
        'whatsappNumber': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gender': _gender,
        'dob': _dob != null ? Timestamp.fromDate(_dob!) : null,
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('clients').doc(widget.client.id).update(updates);

      // Update local model to return immediately
      final updatedClient = widget.client.copyWith(
        name: updates['name'] as String,
        mobile: updates['mobile'] as String,
        altMobile: updates['altMobile'] as String,
        whatsappNumber: updates['whatsappNumber'] as String,
        email: updates['email'] as String,
        address: updates['address'] as String,
        gender: updates['gender'] as String,
        dob: _dob,
        age: updates['age'] as int,
        photoUrl: photoUrl,
      );

      widget.onSave(updatedClient);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Color(0xFFF8F9FE), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          _buildHeader(context, "Edit Personal Info"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) as ImageProvider : null),
                        child: (_imageFile == null && _currentPhotoUrl == null) ?  Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary) : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Tap to change photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Identity"),
                    _buildTextField(context,"Full Name", _nameCtrl, Icons.person),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildDatePicker(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderDropdown()),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Contact Details"),
                    _buildTextField(context,"Primary Mobile", _mobileCtrl, Icons.phone, isNumber: true, isEnabled: false), // Locked
                    const SizedBox(height: 12),
                    _buildTextField(context,"WhatsApp Number", _whatsappCtrl, FontAwesomeIcons.whatsapp, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(context,"Alt Mobile", _altMobileCtrl, Icons.phone_android, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(context,"Email", _emailCtrl, Icons.email),
                    const SizedBox(height: 12),
                    _buildTextField(context,"Address", _addressCtrl, Icons.location_on, maxLines: 3),

                    const SizedBox(height: 40),
                    _buildSaveButton(context,_isSaving, _save),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: _dob ?? DateTime(1990), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (d != null) {
          setState(() {
            _dob = d;
            _ageCtrl.text = (DateTime.now().year - d.year).toString();
          });
        }
      },
      child: Container(
        height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [Icon(Icons.cake, color: Theme.of(context).colorScheme.primary.withOpacity(.4)), const SizedBox(width: 10), Text(_dob == null ? "DOB" : DateFormat('dd MMM yyyy').format(_dob!), style: const TextStyle(fontWeight: FontWeight.w500))]),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender, hint: const Text("Gender"), isExpanded: true,
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. CLIENT TYPE SHEET
// =============================================================================
class ClientTypeSheet extends StatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onSave;

  const ClientTypeSheet({super.key, required this.client, required this.onSave});

  @override
  State<ClientTypeSheet> createState() => _ClientTypeSheetState();
}

class _ClientTypeSheetState extends State<ClientTypeSheet> {
  late String _selectedType;
  bool _isSaving = false;

  final Map<String, String> _types = {
    'new': 'New / Pending',
    'active': 'Active Member',
    'one_time': 'One-Time Consult',
    'expired': 'Expired / Past'
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.client.clientType;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('clients').doc(widget.client.id).update({'clientType': _selectedType});
      widget.onSave(widget.client.copyWith(clientType: _selectedType));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Change Client Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ..._types.entries.map((e) => RadioListTile<String>(
            title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            value: e.key,
            groupValue: _selectedType,
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _selectedType = v!),
          )),
          const SizedBox(height: 20),
          _buildSaveButton(context,_isSaving, _save),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. SECURITY SHEET
// =============================================================================
class ClientSecuritySheet extends StatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onSave;

  const ClientSecuritySheet({super.key, required this.client, required this.onSave});

  @override
  State<ClientSecuritySheet> createState() => _ClientSecuritySheetState();
}

class _ClientSecuritySheetState extends State<ClientSecuritySheet> {
  late bool _isLoginActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isLoginActive = widget.client.status == 'Active';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final newStatus = _isLoginActive ? 'Active' : 'Inactive';
      await FirebaseFirestore.instance.collection('clients').doc(widget.client.id).update({'status': newStatus});
      widget.onSave(widget.client.copyWith(status: newStatus)); // Note: Model update is simplistic here
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // NOTE: Password reset logic should typically be server-side or via auth service
  // For this UI, we assume a button to trigger it.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Security Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("App Login Access", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isLoginActive ? "User can login" : "User blocked", style: TextStyle(fontSize: 12, color: _isLoginActive ? Colors.green : Colors.red)),
                  value: _isLoginActive,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isLoginActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildSaveButton(context,_isSaving, _save),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGET HELPERS
// =============================================================================

Widget _buildHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)));
}

Widget _buildTextField(BuildContext context,String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isEnabled = true}) {
  return Container(
    decoration: BoxDecoration(color: isEnabled ? Colors.white : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
    child: TextFormField(
      controller: ctrl, enabled: isEnabled, keyboardType: isNumber ? TextInputType.phone : TextInputType.text, maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary..withOpacity(.4), size: 20),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => isEnabled && v!.isEmpty ? "Required" : null,
    ),
  );
}

Widget _buildSaveButton(BuildContext context,bool isSaving, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );
}